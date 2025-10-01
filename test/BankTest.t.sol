// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";




// 使用Foundry框架测试Bank合约
contract BankTest is Test {
    Bank public bankContract;
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    address public user4;

    // 在每个测试用例执行前部署合约
    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        user4 = address(0x4);
        
        // 部署Bank合约
        bankContract = new Bank();
    }

    // 测试存款功能 - 验证存款前后余额更新是否正确
    function testDepositBalanceUpdate() public {
        // 准备测试数据
        uint256 depositAmount = 1 ether;
        
        // 检查初始余额
        assertEq(bankContract.balances(admin), 0);
        
        // 执行存款操作
        bankContract.transfer{value: depositAmount}();
        
        // 验证余额更新正确
        assertEq(bankContract.balances(admin), depositAmount);
    }

    // 测试单个用户存款的排行榜功能
    function testTopDepositorsWithSingleUser() public {
        // 用户1存款
        vm.prank(user1);
        bankContract.transfer{value: 1 ether}();
        
        // 获取排行榜
        (address[] memory topUsers, uint256[] memory topAmounts) = bankContract.getTopDepositors();
        
        // 验证排行榜结果
        assertEq(topUsers[0], user1);
        assertEq(topAmounts[0], 1 ether);
        assertEq(topUsers[1], address(0));
        assertEq(topAmounts[1], 0);
        assertEq(topUsers[2], address(0));
        assertEq(topAmounts[2], 0);
    }

    // 测试两个用户存款的排行榜功能
    function testTopDepositorsWithTwoUsers() public {
        // 用户1和用户2存款，用户2存款更多
        vm.prank(user1);
        bankContract.transfer{value: 1 ether}();
        
        vm.prank(user2);
        bankContract.transfer{value: 2 ether}();
        
        // 获取排行榜
        (address[] memory topUsers, uint256[] memory topAmounts) = bankContract.getTopDepositors();
        
        // 验证排行榜结果
        assertEq(topUsers[0], user2);
        assertEq(topAmounts[0], 2 ether);
        assertEq(topUsers[1], user1);
        assertEq(topAmounts[1], 1 ether);
        assertEq(topUsers[2], address(0));
        assertEq(topAmounts[2], 0);
    }

    // 测试三个用户存款的排行榜功能
    function testTopDepositorsWithThreeUsers() public {
        // 三个用户存款，按金额排序：用户3 > 用户2 > 用户1
        vm.prank(user1);
        bankContract.transfer{value: 1 ether}();
        
        vm.prank(user2);
        bankContract.transfer{value: 2 ether}();
        
        vm.prank(user3);
        bankContract.transfer{value: 3 ether}();
        
        // 获取排行榜
        (address[] memory topUsers, uint256[] memory topAmounts) = bankContract.getTopDepositors();
        
        // 验证排行榜结果
        assertEq(topUsers[0], user3);
        assertEq(topAmounts[0], 3 ether);
        assertEq(topUsers[1], user2);
        assertEq(topAmounts[1], 2 ether);
        assertEq(topUsers[2], user1);
        assertEq(topAmounts[2], 1 ether);
    }

    // 测试四个用户存款的排行榜功能（应有一个用户不在排行榜内）
    function testTopDepositorsWithFourUsers() public {
        // 四个用户存款，按金额排序：用户4 > 用户3 > 用户2 > 用户1
        vm.prank(user1);
        bankContract.transfer{value: 1 ether}();
        
        vm.prank(user2);
        bankContract.transfer{value: 2 ether}();
        
        vm.prank(user3);
        bankContract.transfer{value: 3 ether}();
        
        vm.prank(user4);
        bankContract.transfer{value: 4 ether}();
        
        // 获取排行榜
        (address[] memory topUsers, uint256[] memory topAmounts) = bankContract.getTopDepositors();
        
        // 验证排行榜结果 - 用户1不应在排行榜中
        assertEq(topUsers[0], user4);
        assertEq(topAmounts[0], 4 ether);
        assertEq(topUsers[1], user3);
        assertEq(topAmounts[1], 3 ether);
        assertEq(topUsers[2], user2);
        assertEq(topAmounts[2], 2 ether);
        
        // 确认用户1不在排行榜中
        assertTrue(topUsers[0] != user1 && topUsers[1] != user1 && topUsers[2] != user1);
    }

    // 测试同一用户多次存款的情况
    function testSameUserMultipleDeposits() public {
        // 用户1第一次存款
        vm.prank(user1);
        bankContract.transfer{value: 1 ether}();
        
        // 用户1第二次存款
        vm.prank(user1);
        bankContract.transfer{value: 2 ether}();
        
        // 验证总余额
        assertEq(bankContract.balances(user1), 3 ether);
        
        // 验证用户1在排行榜首位
        (address[] memory topUsers, uint256[] memory topAmounts) = bankContract.getTopDepositors();
        assertEq(topUsers[0], user1);
        assertEq(topAmounts[0], 3 ether);
    }

    // 测试管理员可以取款
    function testAdminCanWithdraw() public {
        // 先存入一些资金到合约
        bankContract.transfer{value: 10 ether}();
        
        // 记录管理员取款前余额
        uint256 adminBalanceBefore = address(admin).balance;
        
        // 管理员执行取款
        bankContract.withdraw();
        
        // 验证合约余额为空
        assertEq(address(bankContract).balance, 0);
        
        // 验证管理员余额增加（考虑gas费，这里使用近似验证）
        assertTrue(address(admin).balance > adminBalanceBefore);
    }

    // 测试非管理员不能取款
    function testNonAdminCannotWithdraw() public {
        // 先存入一些资金到合约
        bankContract.transfer{value: 10 ether}();
        
        // 尝试以非管理员身份执行取款，应该失败
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        bankContract.withdraw();
        
        // 验证合约余额未变化
        assertEq(address(bankContract).balance, 10 ether);
    }

    // 测试存款后排行榜动态更新 - 用户排名变化
    function testDynamicRankingUpdate() public {
        // 初始存款：用户1 > 用户2 > 用户3
        vm.prank(user1);
        bankContract.transfer{value: 3 ether}();
        
        vm.prank(user2);
        bankContract.transfer{value: 2 ether}();
        
        vm.prank(user3);
        bankContract.transfer{value: 1 ether}();
        
        // 验证初始排行榜
        (address[] memory topUsersInitial, ) = bankContract.getTopDepositors();
        assertEq(topUsersInitial[0], user1);
        assertEq(topUsersInitial[1], user2);
        assertEq(topUsersInitial[2], user3);
        
        // 用户3再次存款，超过用户1
        vm.prank(user3);
        bankContract.transfer{value: 3 ether}(); // 现在用户3总余额为4 ether
        
        // 验证更新后的排行榜
        (address[] memory topUsersUpdated, ) = bankContract.getTopDepositors();
        assertEq(topUsersUpdated[0], user3); // 用户3现在排名第一
        assertEq(topUsersUpdated[1], user1); // 用户1现在排名第二
        assertEq(topUsersUpdated[2], user2); // 用户2现在排名第三
    }
}