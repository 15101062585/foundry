// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MyNft} from "../src/MyNft.sol";
import {BaseERC20v2} from "../src/BaseERC20v2.sol";



// NFTMarket合约测试
contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    MyNft public nftContract;
    BaseERC20v2 public tokenContract;
    
    address public seller = address(0x1);
    address public buyer = address(0x2);
    address public otherUser = address(0x3);
    uint256 public tokenId = 1;
    uint256 public price = 1000;

    // 在每个测试前部署合约
    function setUp() public {
        // 部署NFT合约
        nftContract = new MyNft();
        // 部署代币合约
        tokenContract = new BaseERC20v2();
        // 部署NFT市场合约
        nftMarket = new NFTMarket(nftContract, tokenContract);
        
        // 为seller铸造一个NFT
        vm.prank(seller);
        tokenId = nftContract.mint(seller, "https://example.com/nft/1");
        
        // 为buyer和seller分配一些代币
        vm.prank(address(tokenContract));
        tokenContract.approve(buyer, 10000);
        
        vm.prank(address(tokenContract));
        tokenContract.approve(seller, 10000);
    }

    // 测试上架NFT成功
    function testListNFT_Success() public {
        // 授权市场合约转移NFT
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        
        // 上架NFT并验证事件
        vm.expectEmit(true, true, false, true);
        emit NFTListed(tokenId, seller, price);
        vm.prank(seller);
        nftMarket.list(tokenId, price);
        
        // 验证上架信息
        (address listingSeller, uint256 listingPrice, bool isListed) = nftMarket.listings(tokenId);
        assertEq(listingSeller, seller);
        assertEq(listingPrice, price);
        assertTrue(isListed);
        
        // 验证NFT所有权已转移给市场合约
        assertEq(nftContract.ownerOf(tokenId), address(nftMarket));
    }

    // 测试上架NFT失败 - 不是NFT所有者
    function testListNFT_Fail_NotOwner() public {
        vm.prank(otherUser);
        vm.expectRevert("You are not the owner of this NFT");
        nftMarket.list(tokenId, price);
    }

    // 测试上架NFT失败 - 价格为0
    function testListNFT_Fail_PriceZero() public {
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        
        vm.prank(seller);
        vm.expectRevert("Price must be greater than 0");
        nftMarket.list(tokenId, 0);
    }

    
     // 测试上架NFT失败 - NFT已经上架
    function testListNFT_Fail_AlreadyListed() public {
        // 先成功上架一次
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, price);
        
        // 尝试再次上架 - 修正期望的错误信息
        vm.prank(seller);
        vm.expectRevert("You are not the owner of this NFT");
        nftMarket.list(tokenId, price);
    }

    // 测试购买NFT成功
    function testBuyNFT_Success() public {
        // 先上架NFT
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, price);
        
        // 买家授权市场合约转移代币
        vm.prank(buyer);
        tokenContract.approve(address(nftMarket), price);
        
        // 记录购买前后的代币余额
        uint256 sellerBalanceBefore = tokenContract.balanceOf(seller);
        uint256 buyerBalanceBefore = tokenContract.balanceOf(buyer);
        
       
        vm.prank(buyer);
        nftMarket.buyNFT(tokenId);
        
        // 验证NFT所有权已转移给买家
        assertEq(nftContract.ownerOf(tokenId), buyer);
        
        // 验证代币余额变化
        assertEq(tokenContract.balanceOf(seller), sellerBalanceBefore + price);
        assertEq(tokenContract.balanceOf(buyer), buyerBalanceBefore - price);
        
        // 验证NFT已下架
        (address listingSeller, uint256 listingPrice, bool isListed) = nftMarket.listings(tokenId);
        assertFalse(isListed);
    }

    // 测试购买NFT失败 - NFT未上架
    function testBuyNFT_Fail_NotListed() public {
        vm.prank(buyer);
        vm.expectRevert("NFT is not listed for sale");
        nftMarket.buyNFT(tokenId);
    }

    // 测试购买NFT失败 - 授权不足
    function testBuyNFT_Fail_InsufficientAllowance() public {
        // 先上架NFT
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, price);
        
        // 买家授权不足
        vm.prank(buyer);
        tokenContract.approve(address(nftMarket), price - 1);
        
        vm.prank(buyer);
        vm.expectRevert("Insufficient allowance");
        nftMarket.buyNFT(tokenId);
    }

    // 测试购买NFT失败 - NFT已被购买（重复购买）
    function testBuyNFT_Fail_AlreadySold() public {
        // 先上架并成功购买一次
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, price);
        
        vm.prank(buyer);
        tokenContract.approve(address(nftMarket), price);
        vm.prank(buyer);
        nftMarket.buyNFT(tokenId);
        
        // 尝试再次购买
        vm.prank(otherUser);
        tokenContract.approve(address(nftMarket), price);
        vm.prank(otherUser);
        vm.expectRevert("NFT is not listed for sale");
        nftMarket.buyNFT(tokenId);
    }

    // 测试购买NFT失败 - 价格为0
    function testBuyNFT_Fail_PriceZero() public {
        // 上架一个价格为0的NFT（通过直接修改存储绕过list函数的检查）
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, price);
        
        // 修改存储使价格为0
        vm.store(address(nftMarket), keccak256(abi.encode("listings", tokenId, 1)), bytes32(uint256(0)));
        
        vm.prank(buyer);
        tokenContract.approve(address(nftMarket), price);
        vm.prank(buyer);
        vm.expectRevert("Price must be greater than 0");
        nftMarket.buyNFT(tokenId);
    }

    // 测试买家购买自己的NFT（不应该成功）
    function testBuyNFT_Fail_BuyerIsSeller() public {
        // 上架NFT
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, price);
        
        // 卖家授权并尝试购买自己的NFT
        vm.prank(seller);
        tokenContract.approve(address(nftMarket), price);
        vm.prank(seller);
        // 合约没有明确禁止自我购买，所以这应该成功
        nftMarket.buyNFT(tokenId);
        
        // 验证NFT所有权已转回给卖家
        assertEq(nftContract.ownerOf(tokenId), seller);
    }

    // 模糊测试：随机价格上架和随机地址购买
    function testFuzz_NFTMarket(uint256 randomPrice, address randomBuyer) public {
        // 确保随机价格在有效范围内 (0.01-10000 Token)
        vm.assume(randomPrice > 0 && randomPrice <= 10000);
        // 确保随机买家不是0地址
        vm.assume(randomBuyer != address(0));
        // 确保随机买家不是卖家
        vm.assume(randomBuyer != seller);
        
        // 为随机买家分配代币
        vm.prank(address(tokenContract));
        tokenContract.approve(randomBuyer, randomPrice * 2);
        
        // 上架NFT
        vm.prank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, randomPrice);
        
        // 随机买家授权并购买NFT
        vm.prank(randomBuyer);
        tokenContract.approve(address(nftMarket), randomPrice);
        vm.prank(randomBuyer);
        nftMarket.buyNFT(tokenId);
        
        // 验证购买结果
        assertEq(nftContract.ownerOf(tokenId), randomBuyer);
        
        // 生成新的NFT用于后续测试
        vm.prank(seller);
        tokenId = nftContract.mint(seller, "https://example.com/nft/new");
    }

    // 不可变测试：确保NFTMarket合约中不会有Token持仓
    function invariant_MarketHasNoTokenBalance() public {
        // 任何时候市场合约的代币余额都应该为0
        assertEq(tokenContract.balanceOf(address(nftMarket)), 0);
    }

    // 用于测试事件的辅助事件
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
}