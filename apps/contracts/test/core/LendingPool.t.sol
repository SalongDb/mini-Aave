// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/LendingPool.sol";
import "../../src/tokens/MockERC20.sol";
import "../../src/tokens/AToken.sol";
import "../../src/oracle/MockOracle.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    MockERC20 token1;
    MockERC20 token2;
    AToken aToken1;
    AToken aToken2;
    MockOracle oracle;

    address user = address(1);

    function setUp() public {
        oracle = new MockOracle();
        pool = new LendingPool(address(oracle));

        // 🔥 Two tokens now
        token1 = new MockERC20("Mock1", "M1");
        token2 = new MockERC20("Mock2", "M2");

        aToken1 = new AToken("aMock1", "aM1", address(pool));
        aToken2 = new AToken("aMock2", "aM2", address(pool));

        pool.addToken(address(token1), address(aToken1));
        pool.addToken(address(token2), address(aToken2));

        // Mint tokens
        token1.mint(user, 1000e18);
        token2.mint(user, 1000e18);

        // Approvals
        vm.startPrank(user);
        token1.approve(address(pool), type(uint256).max);
        token2.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        // Prices
        oracle.setPrice(address(token1), 1e18); // $1
        oracle.setPrice(address(token2), 2e18); // $2
    }

    function testLiquidation() public {
        address liquidator = address(2);

        // Add liquidity
        token2.mint(address(pool), 1000e18);

        vm.startPrank(user);

        // Deposit collateral
        pool.deposit(address(token1), 100e18);

        // Borrow different asset
        pool.borrow(address(token2), 30e18);

        vm.stopPrank();

        // Drop collateral price
        oracle.setPrice(address(token1), 0.5e18);

        // Confirm unhealthy
        assertLt(pool.getHealthFactor(user), 1e18);

        // Setup liquidator
        token2.mint(liquidator, 100e18);

        vm.startPrank(liquidator);
        token2.approve(address(pool), type(uint256).max);

        // Liquidate
        pool.liquidate(
            user,
            address(token2), // debt
            address(token1), // collateral
            20e18
        );

        vm.stopPrank();

        // Assertions
        assertLt(pool.scaledBorrows(user, address(token2)), 30e18);
        assertLt(pool.getUserDeposits(user, address(token1)), 100e18);
        assertGt(token1.balanceOf(liquidator), 0);
    }

    // ----------------------
    // BASIC TESTS
    // ----------------------

    function testDeposit() public {
        vm.prank(user);
        pool.deposit(address(token1), 100e18);

        assertEq(aToken1.balanceOf(user), 100e18);
        assertEq(token1.balanceOf(address(pool)), 100e18);
    }

    function testWithdraw() public {
        vm.startPrank(user);
        pool.deposit(address(token1), 100e18);
        pool.withdraw(address(token1), 50e18);
        vm.stopPrank();

        assertEq(aToken1.balanceOf(user), 50e18);
        assertEq(token1.balanceOf(user), 950e18);
    }

    // ----------------------
    // MULTI TOKEN
    // ----------------------

    function testMultiTokenDeposit() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.deposit(address(token2), 50e18);

        vm.stopPrank();

        assertEq(pool.getUserDeposits(user, address(token1)), 100e18);
        assertEq(pool.getUserDeposits(user, address(token2)), 50e18);
    }

    // ----------------------
    // HEALTH FACTOR
    // ----------------------

    function testHealthFactorNoBorrow() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.deposit(address(token2), 50e18);

        vm.stopPrank();

        uint256 hf = pool.getHealthFactor(user);

        assertEq(hf, type(uint256).max);
    }

    function testBorrowHealthFactor() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18); // $100
        pool.borrow(address(token1), 50e18); // borrow $50

        vm.stopPrank();

        uint256 hf = pool.getHealthFactor(user);

        assertGt(hf, 1e18); // HF > 1
    }

    // ----------------------
    // BORROW SAFETY
    // ----------------------

    function testBorrow() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.borrow(address(token1), 50e18);

        vm.stopPrank();

        assertEq(token1.balanceOf(user), 950e18);
    }

    function testBorrowRevertsIfUnhealthy() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);

        vm.expectRevert();
        pool.borrow(address(token1), 80e18); // exceeds 75%

        vm.stopPrank();
    }

    // ----------------------
    // WITHDRAW SAFETY
    // ----------------------

    function testWithdrawSafe() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.borrow(address(token1), 50e18);

        pool.withdraw(address(token1), 10e18);

        vm.stopPrank();

        assertEq(pool.getUserDeposits(user, address(token1)), 90e18);
    }

    function testWithdrawRevertsIfUnhealthy() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.borrow(address(token1), 50e18);

        vm.expectRevert();
        pool.withdraw(address(token1), 60e18);

        vm.stopPrank();
    }

    function testMultiTokenBorrowPower() public {
        address lender = address(2);

        token1.mint(lender, 500e18);

        vm.startPrank(lender);
        token1.approve(address(pool), type(uint256).max);
        pool.deposit(address(token1), 500e18); // pool now has 500 token1
        vm.stopPrank();

        vm.startPrank(user);

        pool.deposit(address(token1), 100e18); // $100
        pool.deposit(address(token2), 100e18); // $200

        // total collateral = $300
        // borrow limit = 75% → $225

        pool.borrow(address(token1), 200e18); // should PASS

        vm.stopPrank();

        assertEq(pool.scaledBorrows(user, address(token1)), 200e18);

        // user started with 1000, deposited 100 → 900
        // then borrowed 200 → 1100
        assertEq(token1.balanceOf(user), 1100e18);
    }

    function testUtilization() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18); // getUserDeposits = 100
        pool.borrow(address(token1), 50e18); // scaledBorrows = 50

        vm.stopPrank();

        uint256 util = pool.getUtilization(address(token1));

        // Expected = 50%
        assertEq(util, 5e17); // 0.5 * 1e18
    }

    function testBorrowRate() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.borrow(address(token1), 50e18);

        vm.stopPrank();

        uint256 rate = pool.getBorrowRate(address(token1));

        // Expected: 12% = 0.12 * 1e18 = 12e16
        assertEq(rate, 12e16);
    }

    function testAccrueInterest() public {
        oracle.setPrice(address(token1), 1e18);

        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.borrow(address(token1), 50e18);

        vm.stopPrank();

        uint256 beforeBorrow = pool.totalBorrows(address(token1));

        // ⏱️ Move time forward 1 year
        vm.warp(block.timestamp + 365 days);

        // Accrue interest
        pool.accrueInterest(address(token1));

        uint256 afterBorrow = pool.totalBorrows(address(token1));

        // Borrow should increase
        assertGt(afterBorrow, beforeBorrow);
    }

    function testAccrueInterestExact() public {
        oracle.setPrice(address(token1), 1e18);

        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.borrow(address(token1), 50e18);

        vm.stopPrank();

        vm.warp(block.timestamp + 365 days);

        pool.accrueInterest(address(token1));

        uint256 afterBorrow = pool.totalBorrows(address(token1));

        // Expected ≈ 56e18 (50 + 12%)
        assertApproxEqAbs(afterBorrow, 56e18, 1e16); // allow small error
    }

    function testBorrowGrowsOverTime() public {
        vm.startPrank(user);

        pool.deposit(address(token1), 100e18);
        pool.borrow(address(token1), 50e18);

        vm.stopPrank();

        uint256 before = pool.getUserBorrow(user, address(token1));

        vm.warp(block.timestamp + 365 days);

        pool.accrueInterest(address(token1));

        uint256 afterDebt = pool.getUserBorrow(user, address(token1));

        assertGt(afterDebt, before);
    }

    function testLiquidityIndexAccruesInterest() public {
        address borrower = address(2);

        // =============================
        // 1. User getUserDeposits (liquidity provider)
        // =============================
        vm.startPrank(user);
        pool.deposit(address(token1), 100e18);
        vm.stopPrank();

        // =============================
        // 2. Borrower setup
        // =============================
        token1.mint(borrower, 100e18);
        token2.mint(borrower, 100e18);

        vm.startPrank(borrower);
        token2.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);

        // Deposit token2 as collateral ($2 price)
        pool.deposit(address(token2), 50e18); // $100 collateral

        // Borrow token1 ($1 price)
        pool.borrow(address(token1), 50e18); // borrow $50
        vm.stopPrank();

        // =============================
        // 3. Capture initial state
        // =============================
        uint256 initialBalance = pool.getUserDeposits(user, address(token1));
        uint256 initialIndex = pool.liquidityIndex(address(token1));

        // =============================
        // 4. Time passes
        // =============================
        vm.warp(block.timestamp + 365 days); // 1 year

        // trigger interest
        pool.accrueInterest(address(token1));

        // =============================
        // 5. After interest
        // =============================
        uint256 finalBalance = pool.getUserDeposits(user, address(token1));
        uint256 finalIndex = pool.liquidityIndex(address(token1));

        // =============================
        // 6. Assertions
        // =============================

        // 🔥 liquidity index should increase
        assertGt(finalIndex, initialIndex);

        // 🔥 depositor balance should increase
        assertGt(finalBalance, initialBalance);

        // sanity: borrower debt also increased
        uint256 borrowerDebt = pool.getUserBorrow(borrower, address(token1));
        assertGt(borrowerDebt, 50e18);
    }

    function testRepayReducesDebt() public {
        address borrower = address(2);
        address lender = address(3);

        token1.mint(lender, 100e18);
        // =============================

        // 1. Setup borrower
        // =============================
        token2.mint(borrower, 100e18); // collateral
        token1.mint(borrower, 100e18); // for repay later

        vm.startPrank(lender);
        token1.approve(address(pool), type(uint256).max);
        pool.deposit(address(token1), 100e18); // 🔥 provides liquidity
        vm.stopPrank();

        vm.startPrank(borrower);
        token2.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);

        // Deposit collateral ($2 price → strong collateral)
        pool.deposit(address(token2), 50e18); // $100

        // Borrow token1
        pool.borrow(address(token1), 50e18); // $50
        vm.stopPrank();

        // =============================
        // 2. Warp time (interest accrues)
        // =============================
        vm.warp(block.timestamp + 365 days);
        pool.accrueInterest(address(token1));

        // =============================
        // 3. Capture debt before repay
        // =============================
        uint256 debtBefore = pool.getUserBorrow(borrower, address(token1));

        // =============================
        // 4. Repay part of the debt
        // =============================
        vm.startPrank(borrower);
        pool.repay(address(token1), 20e18);
        vm.stopPrank();

        // =============================
        // 5. Capture debt after repay
        // =============================
        uint256 debtAfter = pool.getUserBorrow(borrower, address(token1));

        // =============================
        // 6. Assertions
        // =============================

        // 🔥 Debt should decrease
        assertLt(debtAfter, debtBefore);

        // 🔥 Should reduce roughly by repay amount (allow small diff due to interest)
        assertApproxEqAbs(debtBefore - debtAfter, 20e18, 1e18);
    }
}
