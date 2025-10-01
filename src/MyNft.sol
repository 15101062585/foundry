// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// 若本地没有 OpenZeppelin 库，可以使用 npm 安装：npm install @openzeppelin/contracts
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

contract MyNft is ERC721URIStorage{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    constructor() ERC721(unicode"大理NFT","scenery"){

    }
    //铸造nft
    function mint(address to,string memory tokenURI) public returns (uint256){
        //ntf数量+1;
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(to,newItemId);
        _setTokenURI(newItemId,tokenURI);
        return newItemId;

    }

    
}