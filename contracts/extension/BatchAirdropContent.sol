// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  @title   Batch-mint Metadata
 *  @notice  The `BatchMintMetadata` is a contract extension for any base NFT contract. It lets the smart contract
 *           using this extension set metadata for `n` number of NFTs all at once. This is enabled by storing a single
 *           base URI for a batch of `n` NFTs, where the metadata for each NFT in a relevant batch is `baseURI/tokenId`.
 */

contract BatchAirdropContent {
    /// @dev Largest tokenId of each batch of tokens with the same baseURI.
    uint256[] private batchIds;

    struct AirdropBatch {
        address tokenOwner;
        address tokenAddress;
        uint256 batchEndIndex;
        address[] pointers;
        uint256 pointerIdToProcess;
        uint256 countProcessedInPointer;
    }

    /// @dev Mapping from id of a batch of tokens => to base URI for the respective batch of tokens.
    mapping(uint256 => AirdropBatch) private airdropBatch;

    /**
     *  @notice         Returns the count of batches of NFTs.
     *  @dev            Each batch of tokens has an in ID and an associated `baseURI`.
     *                  See {batchIds}.
     */
    function getBatchCount() public view returns (uint256) {
        return batchIds.length;
    }

    /**
     *  @notice         Returns the ID for the batch of tokens the given tokenId belongs to.
     *  @dev            See {getBaseURICount}.
     *  @param _index   ID of a token.
     */
    // function getBatchIdAtIndex(uint256 _index) public view returns (uint256) {
    //     if (_index >= getBaseURICount()) {
    //         revert("Invalid index");
    //     }
    //     return batchIds[_index];
    // }

    /// @dev Returns the id for the batch of tokens the given tokenId belongs to.
    function _getBatchId(uint256 _checkIndex) internal view returns (uint256 batchId, uint256 index) {
        uint256 numOfBatches = getBatchCount();
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfBatches; i += 1) {
            if (_checkIndex < indices[i]) {
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
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                return baseURI[indices[i]];
            }
        }
        revert("Invalid tokenId");
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function _setBaseURI(uint256 _batchId, string memory _baseURI) internal {
        baseURI[_batchId] = _baseURI;
    }

    function _getBatch(uint256 index) internal view returns (AirdropBatch memory) {
        return airdropBatch[index];
    }

    function _getBatchesToProcess(uint256 _startCount, uint256 _endCount)
        internal
        view
        returns (uint256 startBatchId, uint256 endBatchId)
    {
        uint256[] memory _batchIds = batchIds;
        uint256 batchCount = _batchIds.length;

        for (uint256 i = 0; i < batchCount; i += 1) {
            if (_startCount < _batchIds[i]) {
                startBatchId = i;
                break;
            }
        }

        for (uint256 i = 0; i < batchCount; i += 1) {
            if (_endCount < _batchIds[i]) {
                endBatchId = i;
                break;
            }
        }
    }

    /// @dev Mints a batch of tokenIds and associates a common baseURI to all those Ids.
    function _saveAirdropBatch(
        address _tokenOwner,
        address _tokenAddress,
        uint256 _payeeCount
    ) internal returns (AirdropContent storage) {
        uint256 len = batchIds.length;
        batchIds.push(_payeeCount);

        AirdropBatch memory batch = AirdropBatch({
            tokenOwner: _tokenOwner,
            tokenAddress: _tokenAddress,
            batchEndIndex: _payeeCount
        });

        airdropBatch[len] = batch;

        return airdropBatch[len];
    }
}
