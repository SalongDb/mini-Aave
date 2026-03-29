// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/tokens/AToken.sol";

contract ATokenTest is Test {
    AToken aToken;

    address pool = address(this);
    address user = address(1);

    function setUp() public {
        aToken = new AToken("A Token","aTKN", pool);
    }

    function testMint() public {
        aToken.mint(user, 100e18);

        assertEq(aToken.balanceOf(user), 100e18);
    }

    function testBurn() public {
        aToken.mint(user, 100e18);
        aToken.burn(user, 50e18);

        assertEq(aToken.balanceOf(user), 50e18);
    }

    function testRevertIfNotPool() public {
        vm.prank(user);

        vm.expectRevert("Only pool");
        aToken.mint(user, 100e18);
    }
}