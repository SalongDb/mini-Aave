// SPDX-License-identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/AToken.sol";
import "../interfaces/IOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    address public owner;
    IOracle public oracle;
    address public supportedToken;

    mapping(address => address) public aTokens;
    mapping(address => mapping(address => uint256)) public deposits;
    mapping(address => mapping(address => uint256)) public borrows;

    uint256 public constant COLLATERAL_FACTOR = 75;

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IOracle(_oracle);
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Not owner");
        _;
    }

    function addToken(address token, address aToken) external onlyOwner {
        aTokens[token] = aToken;
        supportedToken = token;
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

        deposits[msg.sender][token] -= amount;

        AToken(aToken).burn(msg.sender,amount);

        IERC20(token).transfer(msg.sender, amount);
    }

    function borrow(address token, uint256 amount) external {
        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        uint256 borrowValue = _getUSDValue(token, amount);
        uint256 maxBorrow = (_getTotalCollateralValue(msg.sender) * COLLATERAL_FACTOR) / 100;

        require( _getTotalBorrowValue(msg.sender) + borrowValue <= maxBorrow, "Exceeds borrow limit");

        borrows[msg.sender][token] += amount;

        IERC20(token).transfer(msg.sender, amount);
    }

    function _getUSDValue(address token, uint256 amount) internal view returns (uint256) {
        uint256 price = oracle.getPrice(token);
        return (amount * price) / 1e18;
    }

    function _getTotalCollateralValue(address user) internal view returns (uint256) {
        uint256 amount = deposits[user][supportedToken];
        uint256 price = oracle.getPrice(supportedToken);

        return (amount * price) / 1e18;
    }

    function _getTotalBorrowValue(address) internal view returns (uint256) {
        return 0;
    }

    function isHealthy(address user, address token, uint256 withdrawAmount) internal view returns (bool) {
        uint256 remaining = deposits[user][token] - withdrawAmount;
        uint256 collateralValue = _getUSDValue(token, remaining);

        uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;

        return _getTotalBorrowValue(user) <= maxBorrow;
    }
}