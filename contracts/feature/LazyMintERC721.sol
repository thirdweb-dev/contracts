// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./LazyMint.sol";
import "../lib/TWStrings.sol";

abstract contract LazyMintERC721 is LazyMint {
    using TWStrings for uint256;

    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI, bytes extraData);

    /// @dev the next available non-minted token id
    uint256 public nextTokenIdToMint;

    /// @dev lazy mint a batch of tokens
    function lazyMint(
        uint256 amount,
        string calldata baseURIForTokens,
        bytes calldata extraData
    ) external virtual override returns (uint256 batchId) {
        require(amount > 0, "Amount must be greater than 0");
        require(_canLazyMint(), "Not authorized");
        uint256 startId = nextTokenIdToMint;
        (nextTokenIdToMint, batchId) = _batchMint(startId, amount, baseURIForTokens);
        emit TokensLazyMinted(startId, startId + amount, baseURIForTokens, extraData);
    }

    /// @dev Returns the URI for a given tokenId
    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {
        string memory batchUri = getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal virtual returns (bool);
}
