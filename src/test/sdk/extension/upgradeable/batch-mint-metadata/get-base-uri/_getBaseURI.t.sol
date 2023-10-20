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

    function getBaseURI(uint256 _tokenId) external view returns (string memory) {
        return _getBaseURI(_tokenId);
    }
}

contract UpgradeableBatchMintMetadata_GetBaseURI is ExtensionUtilTest {
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
            uint256 batchId = startId + amount;
            batchIds.push(batchId);

            string memory baseURI = Strings.toString(batchId);
            (startId, ) = ext.batchMintMetadata(startId, amount, baseURI);
        }
    }

    function test_getBaseURI_invalidTokenId() public {
        uint256 tokenId = batchIds[4]; // tokenId greater than the last batchId

        vm.expectRevert("Invalid tokenId");
        ext.getBaseURI(tokenId);
    }

    modifier whenValidTokenId() {
        _;
    }

    function test_getBaseURI() public whenValidTokenId {
        for (uint256 i = 0; i < 5; i++) {
            uint256 start = i == 0 ? 0 : batchIds[i - 1];
            for (uint256 j = start; j < batchIds[i]; j++) {
                string memory _baseURI = ext.getBaseURI(j);

                assertEq(_baseURI, Strings.toString(batchIds[i]));
            }
        }
    }
}
