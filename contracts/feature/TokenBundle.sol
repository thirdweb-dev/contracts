// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/ITokenBundle.sol";

abstract contract TokenBundle is ITokenBundle {
    uint256 public nextTokenIdToMint;
    mapping(uint256=>BundleInfo) public bundle;

    function getTokenCount(uint256 tokenId) public view returns (uint256) {
        return bundle[tokenId].count;
    }

    function getToken(uint256 tokenId, uint256 index) public view returns (Token memory) {
        return bundle[tokenId].tokens[index];
    }

    function getUri(uint256 tokenId) public view returns (string memory) {
        return bundle[tokenId].uri;
    }
    
    function _getNextTokenId() internal returns (uint256 nextTokenId) {
        nextTokenId = nextTokenIdToMint;
        nextTokenIdToMint += 1;
    }

    function _setBundle(Token[] calldata _tokensToBind, uint256 tokenId) internal {
        for (uint256 i = 0; i < _tokensToBind.length; i += 1) {
            bundle[tokenId].tokens[i] = _tokensToBind[i];
        }
        bundle[tokenId].count = _tokensToBind.length;
    }

    function _setBundleToken(Token memory _tokenToBind, uint256 tokenId, uint256 index) internal {
        bundle[tokenId].tokens[index] = _tokenToBind;
        bundle[tokenId].count += 1;
    }

    function _updateBundleToken(Token memory _tokenToBind, uint256 tokenId, uint256 index) internal {
        bundle[tokenId].tokens[index] = _tokenToBind;
    }

    function _setUri(string calldata _uri, uint256 tokenId) internal {
        bundle[tokenId].uri = _uri;
    }

    function _deleteBundle(uint256 tokenId) internal {
        delete bundle[tokenId];
    }
}