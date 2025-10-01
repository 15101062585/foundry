// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {console} from "forge-std/console.sol";
import {MyToken} from "../src/MyToken.sol";
contract TestStudy is Test {
    Counter public counter;
    address public owner;

    function setUp() public {
        owner = address(0x1);
        vm.prank(owner);
        counter = new Counter();
    }
    //修改区块高度
    function test_roll() public {
        counter.increment();
        assertEq(counter.number(), 1);
        uint256 newBlockNumber =100;
        vm.roll(newBlockNumber);
        console.log("after roll Block number");

        assertEq(block.number, newBlockNumber);
        
    }
    //改变区块时间戳
    function test_Warp() public {
        uint256 newTimestamp = 1694500000;
        vm.warp(newTimestamp);
        console.log("after warp timestamp");
        assertEq(block.timestamp, newTimestamp);
        skip(1000);
        console.log("after skip 1000 timestamp");
        assertEq(block.timestamp, newTimestamp + 1000);
    }

    //更改消息发送者
    function test_Prank() public {
        console.log("current cantract address:", address(this));
        
        console.log("new Owner address:", address(0x1));
        
        address alice = makeAddr("alice");
        console.log("alice address:", alice);

        vm.prank(alice);
        
        
    }

    function test_deal_erc20() public {
        MyToken token = new MyToken("MyToken", "MTK");
        console.log("token address:", address(token));
        address alice = makeAddr("alice");
        console.log("alice address",alice);
        deal(address(token),alice,100 ether);
        console.log("alice token balance:", token.balanceOf(alice));
        
        assertEq(token.balanceOf(alice), 100 ether);
    }
    //断言合约执行错误
    function test_Revert() public {
        vm.expectRevert("Counter: number is even");
        counter.increment();
    }
}