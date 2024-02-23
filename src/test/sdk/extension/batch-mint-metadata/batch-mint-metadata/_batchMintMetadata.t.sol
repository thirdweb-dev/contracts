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

    function getBaseURI(uint256 _tokenId) public view returns (string memory) {
        return _getBaseURI(_tokenId);
    }
}

contract BatchMintMetadata_BatchMintMetadata is ExtensionUtilTest {
    MyBatchMintMetadata internal ext;
    uint256 internal startId;
    uint256 internal amountToMint;
    string internal baseURI;

    function setUp() public override {
        super.setUp();

        ext = new MyBatchMintMetadata();
        startId = 0;
        amountToMint = 100;
        baseURI = "ipfs://baseURI";
    }

    function test_batchMintMetadata() public {
        uint256 prevBaseURICount = ext.getBaseURICount();
        uint256 batchId = startId + amountToMint;

        ext.batchMintMetadata(startId, amountToMint, baseURI);
        uint256 newBaseURICount = ext.getBaseURICount();
        assertEq(ext.getBaseURI(amountToMint - 1), baseURI);
        assertEq(newBaseURICount, prevBaseURICount + 1);
        assertEq(ext.getBatchIdAtIndex(newBaseURICount - 1), batchId);

        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidBatchId.selector, newBaseURICount));
        ext.getBatchIdAtIndex(newBaseURICount);
    }
}
