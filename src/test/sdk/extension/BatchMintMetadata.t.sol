// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { BatchMintMetadata } from "contracts/extension/BatchMintMetadata.sol";

contract MyBatchMintMetadata is BatchMintMetadata {
    function setBaseURI(uint256 _batchId, string memory _baseURI) external {
        _setBaseURI(_batchId, _baseURI);
    }

    function batchMintMetadata(
        uint256 _startId,
        uint256 _amountToMint,
        string memory _baseURIForTokens
    ) external returns (uint256 nextTokenIdToMint, uint256 batchId) {
        (nextTokenIdToMint, batchId) = _batchMintMetadata(_startId, _amountToMint, _baseURIForTokens);
    }

    function viewBaseURI(uint256 _tokenId) external view returns (string memory) {
        return _getBaseURI(_tokenId);
    }
}

contract ExtensionBatchMintMetadata is DSTest, Test {
    MyBatchMintMetadata internal ext;

    function setUp() public {
        ext = new MyBatchMintMetadata();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `batchMintMetadata`
    //////////////////////////////////////////////////////////////*/

    function test_state_batchMintMetadata() public {
        (uint256 nextTokenIdToMint, uint256 batchId) = ext.batchMintMetadata(0, 100, "");
        assertEq(nextTokenIdToMint, 100);
        assertEq(batchId, 100);

        (nextTokenIdToMint, batchId) = ext.batchMintMetadata(100, 100, "");
        assertEq(nextTokenIdToMint, 200);
        assertEq(batchId, 200);

        assertEq(2, ext.getBaseURICount());

        assertEq(100, ext.getBatchIdAtIndex(0));
        assertEq(200, ext.getBatchIdAtIndex(1));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `setBaseURI`
    //////////////////////////////////////////////////////////////*/

    function test_state_setBaseURI() public {
        string memory baseUriOne = "one";
        string memory baseUriTwo = "two";

        (, uint256 batchId) = ext.batchMintMetadata(0, 100, baseUriOne);

        assertEq(baseUriOne, ext.viewBaseURI(10));

        ext.setBaseURI(batchId, baseUriTwo);
        assertEq(baseUriTwo, ext.viewBaseURI(10));
    }
}
