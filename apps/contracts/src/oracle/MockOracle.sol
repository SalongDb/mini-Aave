// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IOracle.sol";

contract MockOracle is IOracle {
    address public owner;

    mapping(address => uint256) public prices;

    constructor () {
        owner = msg.sender;
    }

    function setPrice(address token, uint256 price) external {
        require(msg.sender == owner, "Not owner");
        prices[token] = price;
    }

    function getPrice(address token) external view override returns (uint256) {
        uint256 price = prices[token];
        require(price > 0, "Price not set");
        return price;
    }
} 