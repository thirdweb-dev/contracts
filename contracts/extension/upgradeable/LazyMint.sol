// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/ILazyMint.sol";
import "./BatchMintMetadata.sol";

library LazyMintStorage {
    /// @custom:storage-location erc7201:lazy.mint.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("lazy.mint.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant LAZY_MINT_STORAGE_POSITION =
        0xb9d1563179e0b515350da446a9b78048cef890c6aaa6e34cdf88122d970b5c00;

    struct Data {
        /// @notice The tokenId assigned to the next new NFT to be lazy minted.
        uint256 nextTokenIdToLazyMint;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = LAZY_MINT_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

/**
 *  The `LazyMint` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract, without actually
 *  minting a non-zero balance of NFTs of those tokenIds.
 */

abstract contract LazyMint is ILazyMint, BatchMintMetadata {
    function nextTokenIdToLazyMint() internal view returns (uint256) {
        return _lazyMintStorage().nextTokenIdToLazyMint;
    }

    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The base URI for the 'n' number of NFTs being lazy minted, where the metadata for each
     *                           of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *  @param _data             Additional bytes data to be used at the discretion of the consumer of the contract.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public virtual override returns (uint256 batchId) {
        if (!_canLazyMint()) {
            revert("Not authorized");
        }

        if (_amount == 0) {
            revert("0 amt");
        }

        uint256 startId = _lazyMintStorage().nextTokenIdToLazyMint;

        (_lazyMintStorage().nextTokenIdToLazyMint, batchId) = _batchMintMetadata(startId, _amount, _baseURIForTokens);

        emit TokensLazyMinted(startId, startId + _amount - 1, _baseURIForTokens, _data);

        return batchId;
    }

    /// @dev Returns the LazyMintStorage storage.
    function _lazyMintStorage() internal pure returns (LazyMintStorage.Data storage data) {
        data = LazyMintStorage.data();
    }

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual returns (bool);
}
