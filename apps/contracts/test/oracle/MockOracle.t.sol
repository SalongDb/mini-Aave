// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/oracle/MockOracle.sol";

contract MockOracleTest is Test {
    MockOracle oracle;

    address token = address(1);

    function setUp() public {
        oracle = new MockOracle();
    }

    function testSetAndGetPrice() public {
        oracle.setPrice(token, 1e18);

        uint256 price = oracle.getPrice(token);

        assertEq(price, 1e18);
    }

    function testRevertIfPriceNotSet() public {
        vm.expectRevert("Price not set");
        oracle.getPrice(token);
    }
}