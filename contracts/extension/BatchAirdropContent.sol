// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interfaces/airdrop/IAirdropERC721.sol";

contract BatchAirdropContent {
    uint256[] private batchIds;

    struct AirdropBatch {
        address tokenOwner;
        address tokenAddress;
        uint256 batchEndIndex;
        address[] pointers;
        uint256 pointerIdToProcess;
        uint256 countProcessedInPointer;
    }

    mapping(uint256 => AirdropBatch) private airdropBatch;

    function getBatchCount() public view returns (uint256) {
        return batchIds.length;
    }

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
