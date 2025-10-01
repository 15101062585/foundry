// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {console} from "forge-std/console.sol";

contract MyTokenTest is Test {
    MyToken public myToken;
    address public owner;

    function setUp() public {
        owner = address(0x1);
        vm.prank(owner);
        myToken = new MyToken("MyToken", "MTK");
    }

    function testInitialSupply() public {
        console.log("totalSupply:", myToken.totalSupply());
        assertEq(myToken.totalSupply(), 1e10 * 1e18);
        assertEq(myToken.balanceOf(owner), 1e10 * 1e18);
    }
}