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

    function getBaseURI(uint256 _batchId) external view returns (string memory) {
        return _batchMintMetadataStorage().baseURI[_batchId];
    }
}

contract UpgradeableBatchMintMetadata_BatchMintMetadata is ExtensionUtilTest {
    MyBatchMintMetadataUpg internal ext;
    uint256 internal startId;
    uint256 internal amountToMint;
    string internal baseURI;

    function setUp() public override {
        super.setUp();

        ext = new MyBatchMintMetadataUpg();
        startId = 20;
        amountToMint = 100;
        baseURI = "ipfs://baseURI";
    }

    function test_batchMintMetadata() public {
        uint256 prevBaseURICount = ext.getBaseURICount();
        uint256 batchId = startId + amountToMint;

        ext.batchMintMetadata(startId, amountToMint, baseURI);
        uint256 newBaseURICount = ext.getBaseURICount();
        assertEq(ext.getBaseURI(batchId), baseURI);
        assertEq(newBaseURICount, prevBaseURICount + 1);
        assertEq(ext.getBatchIdAtIndex(newBaseURICount - 1), batchId);

        vm.expectRevert("Invalid index");
        ext.getBatchIdAtIndex(newBaseURICount);
    }
}
