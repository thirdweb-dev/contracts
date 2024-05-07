// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { BatchMintMetadata } from "contracts/extension/upgradeable/BatchMintMetadata.sol";
import "../../../ExtensionUtilTest.sol";

contract MyBatchMintMetadataUpg is BatchMintMetadata {
    function batchMintMetadata(
        uint256 _startId,
        uint256 _amountToMint,
        string memory _baseURIForTokens
    ) external returns (uint256 nextTokenIdToMint, uint256 batchId) {
        (nextTokenIdToMint, batchId) = _batchMintMetadata(_startId, _amountToMint, _baseURIForTokens);
    }

    function getBatchId(uint256 _tokenId) external view returns (uint256 batchId, uint256 index) {
        return _getBatchId(_tokenId);
    }
}

contract UpgradeableBatchMintMetadata_GetBatchId is ExtensionUtilTest {
    MyBatchMintMetadataUpg internal ext;
    uint256 internal startId;
    uint256[] internal batchIds;

    function setUp() public override {
        super.setUp();

        ext = new MyBatchMintMetadataUpg();

        startId = 0;
        // mint 5 batches
        for (uint256 i = 0; i < 5; i++) {
            uint256 amount = (i + 1) * 10;
            batchIds.push(startId + amount);
            (startId, ) = ext.batchMintMetadata(startId, amount, "ipfs://");
        }
    }

    function test_getBatchId_invalidTokenId() public {
        uint256 tokenId = batchIds[4]; // tokenId greater than the last batchId

        vm.expectRevert("Invalid tokenId");
        ext.getBatchId(tokenId);
    }

    modifier whenValidTokenId() {
        _;
    }

    function test_getBatchId() public whenValidTokenId {
        for (uint256 i = 0; i < 5; i++) {
            uint256 start = i == 0 ? 0 : batchIds[i - 1];
            for (uint256 j = start; j < batchIds[i]; j++) {
                (uint256 batchId, uint256 index) = ext.getBatchId(j);

                assertEq(batchId, batchIds[i]);
                assertEq(index, i);
            }
        }
    }
}
