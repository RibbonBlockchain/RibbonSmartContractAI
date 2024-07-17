// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {points} from "../src/points.sol";

contract PointsTest is Test {
    points public _points;

    function setUp() public {
          vm.prank(address(1));
        _points = new points(address(1));
       
    }

    function test_balanceOf() public view {
        assertEq(_points.balanceOf(address(1)),6000000000000000000000000000);
        assertEq(_points.balanceOf(address(_points)),4000000000000000000000000000);
    }

    function test_setVAultAdmin() public {
        vm.prank(address(1));
        _points.setVAultAdmin(address(2));
        assertEq(_points.vaultAdmin(), address(2));
    }
    //  test to create vault
    function test_createVault() public {
        // admin creates vault  it should pass
        vm.prank(address(1));
        bool check=_points.createVault("worldcoin-vault",address(1),address(1),500000000000000000000000);
        assertEq(check,true);
        // non admin creates vault  it should fail
        vm.prank(address(2));
        vm.expectRevert();
       _points.createVault("worldcoin-vault",address(1),address(1),500000000000000000000000);

    }
}
