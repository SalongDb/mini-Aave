// SPDX-License-identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/AToken.sol";
import "../interfaces/IOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    address public owner;
    IOracle public oracle;

    mapping(address => address) public aTokens;
    address[] public supportedTokens;

    mapping(address => mapping(address => uint256)) public scaledBorrows;

    mapping(address => uint256) public totalDeposits;
    mapping(address => uint256) public totalBorrows;

    mapping(address => uint256) public lastUpdated;
    mapping(address => uint256) public borrowIndex;
    mapping(address => uint256) public liquidityIndex;

    uint256 public constant COLLATERAL_FACTOR = 75;
    uint256 public constant LIQUIDATION_BONUS = 10;

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IOracle(_oracle);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addToken(address token, address aToken) external onlyOwner {
        borrowIndex[token] = 1e18;
        liquidityIndex[token] = 1e18;
        lastUpdated[token] = block.timestamp;

        aTokens[token] = aToken;
        supportedTokens.push(token);
    }

    function deposit(address token, uint256 amount) external {
        accrueInterest(token);

        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 index = liquidityIndex[token];
        uint256 scaled = (amount * 1e18) / index;

        AToken(aToken).mint(msg.sender, scaled);
        totalDeposits[token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        accrueInterest(token);

        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        require(
            getUserDeposits(msg.sender, token) >= amount,
            "Not enough balance"
        );

        require(
            _healthFactorAfterWithdraw(msg.sender, token, amount) > 1e18,
            "Unhealthy withdraw"
        );

        uint256 scaledReduction = (amount * 1e18) / liquidityIndex[token];

        uint256 scaledBalance = AToken(aToken).balanceOf(msg.sender);

        require(scaledBalance >= scaledReduction, "Not enough balance");

        AToken(aToken).burn(msg.sender, scaledReduction);
        totalDeposits[token] -= amount;

        IERC20(token).transfer(msg.sender, amount);
    }

    function borrow(address token, uint256 amount) external {
        accrueInterest(token);

        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        uint256 borrowValue = _getUSDValue(token, amount);
        uint256 newBorrowValue = _getTotalBorrowValue(msg.sender) + borrowValue;

        require(
            _healthFactorAfterBorrow(msg.sender, newBorrowValue) > 1e18,
            "Unhealthy borrow"
        );

        uint256 index = borrowIndex[token];

        uint256 scaledAmount = (amount * 1e18) / index;

        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Not enough liquidity"
        );
        scaledBorrows[msg.sender][token] += scaledAmount;
        totalBorrows[token] += amount;

        IERC20(token).transfer(msg.sender, amount);
    }

    function repay(address token, uint256 amount) external {
        accrueInterest(token);

        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        uint256 userDebt = getUserBorrow(msg.sender, token);
        require(userDebt > 0, "No debt");

        // 🔥 Cap repay to user debt (important)
        uint256 repayAmount = amount > userDebt ? userDebt : amount;

        // 🔥 Transfer tokens from user
        IERC20(token).transferFrom(msg.sender, address(this), repayAmount);

        // 🔥 Convert to scaled
        uint256 index = borrowIndex[token];
        uint256 scaledReduction = (repayAmount * 1e18) / index;

        // 🔥 Reduce borrow
        uint256 userScaled = scaledBorrows[msg.sender][token];

        if (amount >= userDebt) {
            // 🔥 full repay → clear dust
            scaledBorrows[msg.sender][token] = 0;
        } else {
            scaledBorrows[msg.sender][token] = userScaled - scaledReduction;
        }
        totalBorrows[token] -= repayAmount;
    }

    function liquidate(
        address user,
        address debtToken,
        address collateralToken,
        uint256 repayAmount
    ) external {
        accrueInterest(debtToken);
        accrueInterest(collateralToken);

        require(getHealthFactor(user) < 1e18, "User is healthy");

        uint256 userDebt = getUserBorrow(user, debtToken);
        require(userDebt >= repayAmount, "Too much repay");

        IERC20(debtToken).transferFrom(msg.sender, address(this), repayAmount);

        uint256 index = borrowIndex[debtToken];
        uint256 scaledReduction = (repayAmount * 1e18) / index;

        scaledBorrows[user][debtToken] -= scaledReduction;
        totalBorrows[debtToken] -= repayAmount;

        uint256 repayValue = _getUSDValue(debtToken, repayAmount);

        uint256 bonusValue = (repayValue * LIQUIDATION_BONUS) / 100;
        uint256 totalValue = repayValue + bonusValue;

        uint256 collateralPrice = oracle.getPrice(collateralToken);
        uint256 collateralAmount = (totalValue * 1e18) / collateralPrice;

        uint256 scaledReduction2 = (collateralAmount * 1e18) /
            liquidityIndex[collateralToken];

        uint256 scaledBalance = AToken(aTokens[collateralToken]).balanceOf(
            user
        );

        require(scaledBalance >= scaledReduction2, "Not enough collateral");

        AToken(aTokens[collateralToken]).burn(user, scaledReduction2);

        IERC20(collateralToken).transfer(msg.sender, collateralAmount);
    }

    function getUserDeposits(
        address user,
        address token
    ) public view returns (uint256) {
        uint256 scaled = AToken(aTokens[token]).balanceOf(user);
        uint256 index = liquidityIndex[token];

        return (scaled * index) / 1e18;
    }

    function _getUSDValue(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 price = oracle.getPrice(token);
        return (amount * price) / 1e18;
    }

    function _getTotalCollateralValue(
        address user
    ) internal view returns (uint256 totalValue) {
        for (uint i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 amount = getUserDeposits(user, token);

            if (amount > 0) {
                uint256 price = oracle.getPrice(token);
                totalValue += (amount * price) / 1e18;
            }
        }
    }

    function _getTotalBorrowValue(
        address user
    ) internal view returns (uint256 totalValue) {
        for (uint i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 amount = getUserBorrow(user, token);

            if (amount > 0) {
                uint256 price = oracle.getPrice(token);
                totalValue += (amount * price) / 1e18;
            }
        }
    }

    function getHealthFactor(address user) public view returns (uint256) {
        uint256 totalBorrow = _getTotalBorrowValue(user);

        if (totalBorrow == 0) {
            return type(uint256).max;
        }

        uint256 totalCollateral = _getTotalCollateralValue(user);

        uint256 adjustedCollateral = (totalCollateral * COLLATERAL_FACTOR) /
            100;

        return (adjustedCollateral * 1e18) / totalBorrow;
    }

    function _healthFactorAfterBorrow(
        address user,
        uint256 newBorrowValue
    ) internal view returns (uint256) {
        uint256 totalCollateral = _getTotalCollateralValue(user);
        uint256 adjustedCollateral = (totalCollateral * COLLATERAL_FACTOR) /
            100;

        return (adjustedCollateral * 1e18) / newBorrowValue;
    }

    function _healthFactorAfterWithdraw(
        address user,
        address token,
        uint256 withdrawAmount
    ) internal view returns (uint256) {
        uint256 totalBorrow = _getTotalBorrowValue(user);

        if (totalBorrow == 0) {
            return type(uint256).max;
        }

        uint256 totalCollateral = _getTotalCollateralValue(user);
        uint256 withdrawValue = _getUSDValue(token, withdrawAmount);

        uint256 newCollateral = totalCollateral - withdrawValue;
        uint256 adjustedCollateral = (newCollateral * COLLATERAL_FACTOR) / 100;

        return (adjustedCollateral * 1e18) / totalBorrow;
    }

    function getUtilization(address token) public view returns (uint256) {
        uint256 tokenDeposits = totalDeposits[token];
        uint256 tokenBorrows = totalBorrows[token];

        if (tokenDeposits == 0) return 0;

        return (tokenBorrows * 1e18) / tokenDeposits;
    }

    function getBorrowRate(address token) public view returns (uint256) {
        uint256 util = getUtilization(token);

        uint256 baseRate = 2e16;
        uint256 slope = 20e16;

        return baseRate + (util * slope) / 1e18;
    }

    function getUserBorrow(
        address user,
        address token
    ) public view returns (uint256) {
        uint256 scaled = scaledBorrows[user][token];
        uint256 index = borrowIndex[token];

        return (scaled * index) / 1e18;
    }

    function accrueInterest(address token) public {
        uint256 timeElapsed = block.timestamp - lastUpdated[token];

        if (timeElapsed == 0) return;

        uint256 borrows = totalBorrows[token];
        if (borrows == 0) {
            lastUpdated[token] = block.timestamp;
            return;
        }

        uint256 rate = getBorrowRate(token);
        uint256 interestFactor = (rate * timeElapsed) / (365 days);

        // 🔥 update index
        borrowIndex[token] =
            borrowIndex[token] +
            (borrowIndex[token] * interestFactor) /
            1e18;

        // update total borrows
        uint256 interest = (borrows * interestFactor) / 1e18;
        totalBorrows[token] += interest;

        if (totalDeposits[token] > 0) {
            uint256 liquidityGain = (interest * 1e18) / totalDeposits[token];

            liquidityIndex[token] =
                liquidityIndex[token] +
                (liquidityIndex[token] * liquidityGain) /
                1e18;
        }
        lastUpdated[token] = block.timestamp;
    }
}
