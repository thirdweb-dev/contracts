// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/ILazyMint.sol";
import "./BatchMintMetadata.sol";

/**
 *  Thirdweb's `LazyMint` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract, without actually
 *  minting a non-zero balance of NFTs of those tokenIds.
 */

abstract contract LazyMintUpdated is ILazyMint, BatchMintMetadata {

    error LazyMint__ZeroAmount();
    error LazyMint__NotAuthorized();

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes data);

    uint256 public nextTokenIdToLazyMint;

    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) external virtual returns (uint256 batchId) {
        if(!_canLazyMint()) {
            revert LazyMint__NotAuthorized();
        }
        
        if (_amount == 0) {
            revert LazyMint__ZeroAmount();
        }

        uint256 startId = nextTokenIdToLazyMint;

        (nextTokenIdToLazyMint, batchId) = _batchMint(startId, _amount, _baseURIForTokens);

        emit TokensLazyMinted(startId, startId + _amount - 1, _baseURIForTokens, _data);
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual returns (bool);
}
