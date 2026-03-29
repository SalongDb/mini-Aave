// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AToken is ERC20 {
    address public pool;

    modifier onlyPool() {
        require(msg.sender == pool,"Only pool");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _pool
    ) ERC20(name, symbol) {
        pool = _pool;
    }

    function mint(address to, uint256 amount) external onlyPool {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyPool {
        _burn(from, amount);
    }
}