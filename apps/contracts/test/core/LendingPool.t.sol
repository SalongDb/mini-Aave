// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/LendingPool.sol";
import "../../src/tokens/MockERC20.sol";
import "../../src/tokens/AToken.sol";
import "../../src/oracle/MockOracle.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    MockERC20 token;
    AToken aToken;
    MockOracle oracle;

    address user = address(1);

    function setUp() public {
        oracle = new MockOracle();
        pool = new LendingPool(address(oracle));

        token = new MockERC20("Mock", "MOCK");
        aToken = new AToken("aMock", "aMock", address(pool));

        pool.addToken(address(token), address(aToken));

        token.mint(user, 100e18);

        vm.startPrank(user);
        token.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testDeposit() public {
        vm.prank(user);
        pool.deposit(address(token), 100e18);

        assertEq(aToken.balanceOf(user), 100e18);
        assertEq(token.balanceOf(address(pool)), 100e18);
    }

    function testwithdraw() public {
        vm.startPrank(user);
        pool.deposit(address(token), 100e18);
        pool.withdraw(address(token), 50e18);
        vm.stopPrank();

        assertEq(aToken.balanceOf(user), 50e18);
        assertEq(token.balanceOf(user), 50e18);
    }

    function testBorrow() public {
        oracle.setPrice(address(token), 1e18);

        vm.startPrank(user);
        pool.deposit(address(token), 100e18);

        pool.borrow(address(token), 50e18);
        vm.stopPrank();

        assertEq(token.balanceOf(user), 50e18);
    }
}
