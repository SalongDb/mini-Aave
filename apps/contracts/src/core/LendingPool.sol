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

    mapping(address => mapping(address => uint256)) public deposits;
    mapping(address => mapping(address => uint256)) public borrows;

    uint256 public constant COLLATERAL_FACTOR = 75;
    uint256 public constant LIQUIDITION_BONUS = 10;

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IOracle(_oracle);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addToken(address token, address aToken) external onlyOwner {

        aTokens[token] = aToken;
        supportedTokens.push(token);
    }

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender][token] += amount;

        AToken(aToken).mint(msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external {
        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        require(deposits[msg.sender][token] >= amount, "Not enough balance");

        require(
            _healthFactorAfterWithdraw(msg.sender, token, amount) > 1e18,
            "Unhealthy withdraw"
        );

        deposits[msg.sender][token] -= amount;

        AToken(aToken).burn(msg.sender, amount);

        IERC20(token).transfer(msg.sender, amount);
    }

    function borrow(address token, uint256 amount) external {
        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        uint256 borrowValue = _getUSDValue(token, amount);
        uint256 newBorrowValue = _getTotalBorrowValue(msg.sender) + borrowValue;

        require(
            _healthFactorAfterBorrow(msg.sender, newBorrowValue) > 1e18,
            "Unhealthy borrow"
        );

        borrows[msg.sender][token] += amount;

        IERC20(token).transfer(msg.sender, amount);
    }

    function liquidate(
        address user,
        address debtToken,
        address collateralToken,
        uint256 repayAmount
    ) external {
        require(getHealthFactor(user) < 1e18, "User is healthy");

        require(borrows[user][debtToken] >= repayAmount, "Too much repay");

        IERC20(debtToken).transferFrom(msg.sender, address(this), repayAmount);

        borrows[user][debtToken] -= repayAmount;

        uint256 repayValue = _getUSDValue(debtToken,repayAmount);

        uint256 bonusValue = (repayValue * LIQUIDITION_BONUS) / 100;
        uint256 totalValue = repayValue + bonusValue;

        uint256 collateralPrice = oracle.getPrice(collateralToken);
        uint256 collateralAmount = (totalValue * 1e18) / collateralPrice;

        require( deposits[user][collateralToken] >= collateralAmount, "Not enough collateral");

        deposits[user][collateralToken] -= collateralAmount;

        IERC20(collateralToken).transfer(msg.sender, collateralAmount);
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
            uint256 amount = deposits[user][token];

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
            uint256 amount = borrows[user][token];

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
        uint256 adjustedCollateral = (totalCollateral * COLLATERAL_FACTOR) / 100;

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
}
