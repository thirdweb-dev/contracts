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

    function freezeBaseURI(uint256 _batchId) external {
        _freezeBaseURI(_batchId);
    }

    function batchFrozen(uint256 _batchId) external view returns (bool) {
        return _batchMintMetadataStorage().batchFrozen[_batchId];
    }
}

contract UpgradeableBatchMintMetadata_FreezeBaseURI is ExtensionUtilTest {
    MyBatchMintMetadataUpg internal ext;
    uint256 internal startId;
    uint256[] internal batchIds;
    uint256 internal indexToFreeze;

    event MetadataFrozen();

    function setUp() public override {
        super.setUp();

        ext = new MyBatchMintMetadataUpg();

        startId = 0;
        // mint 5 batches
        for (uint256 i = 0; i < 5; i++) {
            uint256 amount = (i + 1) * 10;
            uint256 batchId = startId + amount;
            batchIds.push(batchId);

            (startId, ) = ext.batchMintMetadata(startId, amount, "ipfs://");
            assertEq(ext.batchFrozen(batchId), false);
        }

        indexToFreeze = 3;
    }

    function test_freezeBaseURI_invalidBatch() public {
        vm.expectRevert("Invalid batch");
        ext.freezeBaseURI(batchIds[indexToFreeze] * 10); // non-existent batchId
    }

    modifier whenBatchIdValid() {
        _;
    }

    function test_freezeBaseURI() public whenBatchIdValid {
        ext.freezeBaseURI(batchIds[indexToFreeze]);

        assertEq(ext.batchFrozen(batchIds[indexToFreeze]), true);
    }

    function test_freezeBaseURI_event() public whenBatchIdValid {
        vm.expectEmit(false, false, false, false);
        emit MetadataFrozen();
        ext.freezeBaseURI(batchIds[indexToFreeze]);
    }
}
