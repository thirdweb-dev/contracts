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

    function setBaseURI(uint256 _batchId, string memory _baseURI) external {
        _setBaseURI(_batchId, _baseURI);
    }

    function freezeBaseURI(uint256 _batchId, bool _freeze) external {
        _batchMintMetadataStorage().batchFrozen[_batchId] = _freeze;
    }

    function getBaseURI(uint256 _batchId) external view returns (string memory) {
        return _batchMintMetadataStorage().baseURI[_batchId];
    }
}

contract UpgradeableBatchMintMetadata_SetBaseURI is ExtensionUtilTest {
    MyBatchMintMetadataUpg internal ext;
    string internal newBaseURI;
    uint256 internal startId;
    uint256[] internal batchIds;
    uint256 internal indexToUpdate;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

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
            ext.freezeBaseURI(batchId, true);
        }

        indexToUpdate = 3;
        newBaseURI = "ipfs://baseURI";
    }

    function test_setBaseURI_frozenBatchId() public {
        vm.expectRevert("Batch frozen");
        ext.setBaseURI(batchIds[indexToUpdate], newBaseURI);
    }

    modifier whenBatchIdNotFrozen() {
        ext.freezeBaseURI(batchIds[indexToUpdate], false);
        _;
    }

    function test_setBaseURI() public whenBatchIdNotFrozen {
        ext.setBaseURI(batchIds[indexToUpdate], newBaseURI);

        string memory _baseURI = ext.getBaseURI(batchIds[indexToUpdate]);

        assertEq(_baseURI, newBaseURI);
    }

    function test_setBaseURI_event() public whenBatchIdNotFrozen {
        vm.expectEmit(false, false, false, true);
        emit BatchMetadataUpdate(batchIds[indexToUpdate - 1], batchIds[indexToUpdate]);
        ext.setBaseURI(batchIds[indexToUpdate], newBaseURI);
    }
}
