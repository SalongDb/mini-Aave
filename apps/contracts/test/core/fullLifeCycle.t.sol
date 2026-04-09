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

    function testFullLifecycle() public {
        address lender = address(2);
        address borrower = address(3);

        // =============================
        // 1. LENDER provides liquidity
        // =============================
        token1.mint(lender, 1000e18);

        vm.startPrank(lender);
        token1.approve(address(pool), type(uint256).max);
        pool.deposit(address(token1), 1000e18);
        vm.stopPrank();

        // =============================
        // 2. BORROWER deposits collateral
        // =============================
        token2.mint(borrower, 100e18);

        vm.startPrank(borrower);
        token2.approve(address(pool), type(uint256).max);
        pool.deposit(address(token2), 50e18); // $100 collateral
        vm.stopPrank();

        // =============================
        // 3. BORROWER borrows
        // =============================
        vm.startPrank(borrower);
        pool.borrow(address(token1), 50e18); // $50 borrow
        vm.stopPrank();

        uint256 debtBefore = pool.getUserBorrow(borrower, address(token1));
        assertGt(debtBefore, 0);
        
        // =============================
        // 4. TIME PASSES → interest accrues
        // =============================
        vm.warp(block.timestamp + 365 days);
        pool.accrueInterest(address(token1));

        uint256 debtAfterInterest = pool.getUserBorrow(
            borrower,
            address(token1)
        );
        assertGt(debtAfterInterest, debtBefore); // interest increased

        // =============================
        // 5. BORROWER repays part
        // =============================
        token1.mint(borrower, 100e18);

        vm.startPrank(borrower);
        token1.approve(address(pool), type(uint256).max);
        pool.repay(address(token1), 30e18);
        vm.stopPrank();

        uint256 debtAfterRepay = pool.getUserBorrow(borrower, address(token1));
        assertLt(debtAfterRepay, debtAfterInterest);

        // =============================
        // 6. BORROWER repays fully
        // =============================
        vm.startPrank(borrower);
        pool.repay(address(token1), type(uint256).max);
        vm.stopPrank();

        uint256 finalDebt = pool.getUserBorrow(borrower, address(token1));
        assertEq(finalDebt, 0);

        // =============================
        // 7. BORROWER withdraws collateral
        // =============================
        vm.startPrank(borrower);
        pool.withdraw(address(token2), 50e18);
        vm.stopPrank();

        uint256 finalCollateral = pool.getUserDeposits(
            borrower,
            address(token2)
        );
        assertEq(finalCollateral, 0);

        // =============================
        // 8. LENDER earns interest
        // =============================
        uint256 lenderBalance = pool.getUserDeposits(lender, address(token1));

        // should be > initial deposit due to interest
        assertGt(lenderBalance, 1000e18);
    }
}
