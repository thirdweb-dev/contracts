// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./LazyMint.sol";

abstract contract LazyMintERC721 is LazyMint {
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

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal virtual returns (bool);
}
