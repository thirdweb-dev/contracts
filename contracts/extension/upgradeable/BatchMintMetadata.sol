// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library BatchMintMetadataStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant BATCH_MINT_METADATA_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("batch.mint.metadata.storage")) - 1));

    struct Data {
        /// @dev Largest tokenId of each batch of tokens with the same baseURI.
        uint256[] batchIds;
        /// @dev Mapping from id of a batch of tokens => to base URI for the respective batch of tokens.
        mapping(uint256 => string) baseURI;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = BATCH_MINT_METADATA_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

/**
 *  @title   Batch-mint Metadata
 *  @notice  The `BatchMintMetadata` is a contract extension for any base NFT contract. It lets the smart contract
 *           using this extension set metadata for `n` number of NFTs all at once. This is enabled by storing a single
 *           base URI for a batch of `n` NFTs, where the metadata for each NFT in a relevant batch is `baseURI/tokenId`.
 */

contract BatchMintMetadata {
    /**
     *  @notice         Returns the count of batches of NFTs.
     *  @dev            Each batch of tokens has an in ID and an associated `baseURI`.
     *                  See {batchIds}.
     */
    function getBaseURICount() public view returns (uint256) {
        return _batchMintMetadataStorage().batchIds.length;
    }

    /**
     *  @notice         Returns the ID for the batch of tokens the given tokenId belongs to.
     *  @dev            See {getBaseURICount}.
     *  @param _index   ID of a token.
     */
    function getBatchIdAtIndex(uint256 _index) public view returns (uint256) {
        if (_index >= getBaseURICount()) {
            revert("Invalid index");
        }
        return _batchMintMetadataStorage().batchIds[_index];
    }

    /// @dev Returns the id for the batch of tokens the given tokenId belongs to.
    function _getBatchId(uint256 _tokenId) internal view returns (uint256 batchId, uint256 index) {
        uint256 numOfTokenBatches = getBaseURICount();
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
        uint256 numOfTokenBatches = getBaseURICount();
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

    /// @dev Returns the BatchMintMetadata storage.
    function _batchMintMetadataStorage() internal pure returns (BatchMintMetadataStorage.Data storage data) {
        data = BatchMintMetadataStorage.data();
    }
}
