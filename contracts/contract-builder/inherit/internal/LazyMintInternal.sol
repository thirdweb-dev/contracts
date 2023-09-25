// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { LazyMintStorage } from "../../../extension/upgradeable/LazyMint.sol";
import { BatchMintMetadataStorage } from "../../../extension/upgradeable/BatchMintMetadata.sol";
import { DelayedRevealStorage } from "../../../extension/upgradeable/DelayedReveal.sol";

contract LazyMintInternal {
    function _nextTokenIdToLazyMint() internal view returns (uint256) {
        return _lazyMintStorage().nextTokenIdToLazyMint;
    }

    function _getBaseURICount() internal view returns (uint256) {
        return _batchMintMetadataStorage().batchIds.length;
    }

    /// @dev Returns the id for the batch of tokens the given tokenId belongs to.
    function _getBatchId(uint256 _tokenId) internal view returns (uint256 batchId, uint256 index) {
        uint256 numOfTokenBatches = _getBaseURICount();
        uint256[] memory indices = _batchMintMetadataStorage().batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                index = i;
                batchId = indices[i];

                return (batchId, index);
            }
        }

        revert("Invalid tokenId");
    }

    /// @dev Returns the baseURI for a token. The intended metadata URI for the token is baseURI + tokenId.
    function _getBaseURI(uint256 _tokenId) internal view returns (string memory) {
        uint256 numOfTokenBatches = _getBaseURICount();
        uint256[] memory indices = _batchMintMetadataStorage().batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                return _batchMintMetadataStorage().baseURI[indices[i]];
            }
        }
        revert("Invalid tokenId");
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function _setBaseURI(uint256 _batchId, string memory _baseURI) internal {
        _batchMintMetadataStorage().baseURI[_batchId] = _baseURI;
    }

    /// @dev Mints a batch of tokenIds and associates a common baseURI to all those Ids.
    function _batchMintMetadata(
        uint256 _startId,
        uint256 _amountToMint,
        string memory _baseURIForTokens
    ) internal returns (uint256 nextTokenIdToMint, uint256 batchId) {
        batchId = _startId + _amountToMint;
        nextTokenIdToMint = batchId;

        _batchMintMetadataStorage().batchIds.push(batchId);
        _batchMintMetadataStorage().baseURI[batchId] = _baseURIForTokens;
    }

    /**
     *  @notice         Returns whether the relvant batch of NFTs is subject to a delayed reveal.
     *  @dev            Returns `true` if `_batchId`'s base URI is encrypted.
     *  @param _batchId ID of a batch of NFTs.
     */
    function _isEncryptedBatch(uint256 _batchId) internal view returns (bool) {
        return _delayedRevealStorage().encryptedData[_batchId].length > 0;
    }

    /// @dev Returns the LazyMintStorage storage.
    function _lazyMintStorage() internal pure returns (LazyMintStorage.Data storage data) {
        data = LazyMintStorage.data();
    }

    /// @dev Returns the BatchMintMetadata storage.
    function _batchMintMetadataStorage() internal pure returns (BatchMintMetadataStorage.Data storage data) {
        data = BatchMintMetadataStorage.data();
    }

    /// @dev Returns the DelayedReveal storage.
    function _delayedRevealStorage() internal pure returns (DelayedRevealStorage.Data storage data) {
        data = DelayedRevealStorage.data();
    }
}
