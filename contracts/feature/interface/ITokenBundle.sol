// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITokenBundle {

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct Token {
        address assetContract;
        TokenType tokenType;
        uint256 tokenId;
        uint256 totalAmountPacked;
        
    }

    struct BundleInfo {
        uint256 count;
        string uri;
        mapping(uint256=>Token) tokens;
    }

}