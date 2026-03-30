// SPDX-License-identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/AToken.sol";
import "../interfaces/IOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    address public owner;
    IOracle public oracle;

    mapping(address => address) public aTokens;

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
    }

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        AToken(aToken).mint(msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external {
        require(amount > 0, "Amount = 0");

        address aToken = aTokens[token];
        require(aToken != address(0), "Token not supported");

        AToken(aToken).burn(msg.sender,amount);

        IERC20(token).transfer(msg.sender, amount);
    }
}