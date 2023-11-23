// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library BatchMintMetadataStorage {
    /// @custom:storage-location erc7201:batch.mint.metadata.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("batch.mint.metadata.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant BATCH_MINT_METADATA_STORAGE_POSITION =
        0xf5b99f0648d517803cfbd359284c3fd81ac54e1c89b4874d917ae042d05e8500;

    struct Data {
        /// @dev Largest tokenId of each batch of tokens with the same baseURI.
        uint256[] batchIds;
        /// @dev Mapping from id of a batch of tokens => to base URI for the respective batch of tokens.
        mapping(uint256 => string) baseURI;
        /// @dev Mapping from id of a batch of tokens => to whether the base URI for the respective batch of tokens is frozen.
        mapping(uint256 => bool) batchFrozen;
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
    /// @dev This event emits when the metadata of all tokens are frozen.
    /// While not currently supported by marketplaces, this event allows
    /// future indexing if desired.
    event MetadataFrozen();

    // @dev This event emits when the metadata of a range of tokens is updated.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

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

    /// @dev returns the starting tokenId of a given batchId.
    function _getBatchStartId(uint256 _batchID) internal view returns (uint256) {
        uint256 numOfTokenBatches = getBaseURICount();
        uint256[] memory indices = _batchMintMetadataStorage().batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i++) {
            if (_batchID == indices[i]) {
                if (i > 0) {
                    return indices[i - 1];
                }
                return 0;
            }
        }
        revert("Invalid batchId");
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function _setBaseURI(uint256 _batchId, string memory _baseURI) internal {
        require(!_batchMintMetadataStorage().batchFrozen[_batchId], "Batch frozen");
        _batchMintMetadataStorage().baseURI[_batchId] = _baseURI;
        emit BatchMetadataUpdate(_getBatchStartId(_batchId), _batchId);
    }

    /// @dev Freezes the base URI for the batch of tokens with the given batchId.
    function _freezeBaseURI(uint256 _batchId) internal {
        string memory baseURIForBatch = _batchMintMetadataStorage().baseURI[_batchId];
        require(bytes(baseURIForBatch).length > 0, "Invalid batch");
        _batchMintMetadataStorage().batchFrozen[_batchId] = true;
        emit MetadataFrozen();
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
