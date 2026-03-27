// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/tokens/MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("Mock Token", "MTK");
    }

    function testMint() public {
        token.mint(address(this), 1000);

        assertEq(token.balanceOf(address(this)), 1000);
    }
}