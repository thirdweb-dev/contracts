// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { BatchMintMetadata } from "contracts/extension/BatchMintMetadata.sol";
import "../../ExtensionUtilTest.sol";

contract MyBatchMintMetadata is BatchMintMetadata {
    function batchMintMetadata(
        uint256 _startId,
        uint256 _amountToMint,
        string memory _baseURIForTokens
    ) external returns (uint256 nextTokenIdToMint, uint256 batchId) {
        (nextTokenIdToMint, batchId) = _batchMintMetadata(_startId, _amountToMint, _baseURIForTokens);
    }

    function getBatchStartId(uint256 _batchId) external view returns (uint256) {
        return _getBatchStartId(_batchId);
    }
}

contract BatchMintMetadata_GetBatchStartId is ExtensionUtilTest {
    MyBatchMintMetadata internal ext;
    uint256 internal startId;
    uint256[] internal batchIds;

    function setUp() public override {
        super.setUp();

        ext = new MyBatchMintMetadata();

        startId = 0;
        // mint 5 batches
        for (uint256 i = 0; i < 5; i++) {
            uint256 amount = (i + 1) * 10;
            batchIds.push(startId + amount);
            (startId, ) = ext.batchMintMetadata(startId, amount, "ipfs://");
        }
    }

    function test_getBatchStartId_invalidBatchId() public {
        uint256 batchId = batchIds[4] + 1; // non-existent batchId

        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidBatchId.selector, batchId));
        ext.getBatchStartId(batchId);
    }

    modifier whenValidBatchId() {
        _;
    }

    function test_getBatchStartId() public whenValidBatchId {
        for (uint256 i = 0; i < 5; i++) {
            uint256 start = i == 0 ? 0 : batchIds[i - 1];
            uint256 _batchStartId = ext.getBatchStartId(batchIds[i]);

            assertEq(start, _batchStartId);
        }
    }
}
