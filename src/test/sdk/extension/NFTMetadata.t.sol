// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { NFTMetadata } from "contracts/extension/NFTMetadata.sol";

contract NFTMetadataHarness is NFTMetadata {
    address private authorized;

    constructor() {
        authorized = msg.sender;
    }

    function _canSetMetadata(uint256 /*_tokenId*/) internal view override returns (bool) {
        if (msg.sender == authorized) return true;
        return false;
    }

    function _canFreezeMetadata(uint256 _tokenId) internal pure override returns (bool) {
        if (_tokenId % 2 == 0) return true;
        return false;
    }

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return _getTokenURI(_tokenId);
    }

    function frozenURIStatus(uint256 _tokenId) external view returns (bool) {
        return _URIFrozen[_tokenId];
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {}
}

contract ExtensionNFTMetadata is DSTest, Test {
    NFTMetadataHarness internal ext;

    function setUp() public {
        ext = new NFTMetadataHarness();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `setTokenURI`
    //////////////////////////////////////////////////////////////*/

    function test_setTokenURI_state() public {
        string memory uri = "test";
        ext.setTokenURI(0, uri);
        assertEq(ext.getTokenURI(0), uri);

        string memory uri2 = "test2";
        ext.setTokenURI(0, uri2);
        assertEq(ext.getTokenURI(0), uri2);
    }

    function test_setTokenURI_revert_notAuthorized() public {
        vm.startPrank(address(0x1));
        string memory uri = "test";
        vm.expectRevert("NFTMetadata: not authorized to set metadata.");
        ext.setTokenURI(1, uri);
    }

    function test_setTokenURI_revert_emptyMetadata() public {
        string memory uri = "";
        vm.expectRevert("NFTMetadata: empty metadata.");
        ext.setTokenURI(1, uri);
    }

    function test_setTokenURI_revert_frozen() public {
        ext.freezeTokenURI(2);
        string memory uri = "test";
        vm.expectRevert("NFTMetadata: metadata is frozen.");
        ext.setTokenURI(2, uri);
    }

    function test_freezeTokenURI_state() public {
        ext.freezeTokenURI(0);
        assertEq(ext.frozenURIStatus(0), true);
    }

    function test_freezeTokenURI_revert_notAuthorized() public {
        vm.expectRevert("NFTMetadata: not authorized to freeze metdata");
        ext.freezeTokenURI(1);
    }
}

// contract MyBatchMintMetadata is BatchMintMetadata {
//     function setBaseURI(uint256 _batchId, string memory _baseURI) external {
//         _setBaseURI(_batchId, _baseURI);
//     }

//     function batchMintMetadata(
//         uint256 _startId,
//         uint256 _amountToMint,
//         string memory _baseURIForTokens
//     ) external returns (uint256 nextTokenIdToMint, uint256 batchId) {
//         (nextTokenIdToMint, batchId) = _batchMintMetadata(_startId, _amountToMint, _baseURIForTokens);
//     }

//     function viewBaseURI(uint256 _tokenId) external view returns (string memory) {
//         return _getBaseURI(_tokenId);
//     }
// }

// contract ExtensionBatchMintMetadata is DSTest, Test {
//     MyBatchMintMetadata internal ext;

//     function setUp() public {
//         ext = new MyBatchMintMetadata();
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Unit tests: `batchMintMetadata`
//     //////////////////////////////////////////////////////////////*/

//     function test_state_batchMintMetadata() public {
//         (uint256 nextTokenIdToMint, uint256 batchId) = ext.batchMintMetadata(0, 100, "");
//         assertEq(nextTokenIdToMint, 100);
//         assertEq(batchId, 100);

//         (nextTokenIdToMint, batchId) = ext.batchMintMetadata(100, 100, "");
//         assertEq(nextTokenIdToMint, 200);
//         assertEq(batchId, 200);

//         assertEq(2, ext.getBaseURICount());

//         assertEq(100, ext.getBatchIdAtIndex(0));
//         assertEq(200, ext.getBatchIdAtIndex(1));
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Unit tests: `setBaseURI`
//     //////////////////////////////////////////////////////////////*/

//     function test_state_setBaseURI() public {
//         string memory baseUriOne = "one";
//         string memory baseUriTwo = "two";

//         (, uint256 batchId) = ext.batchMintMetadata(0, 100, baseUriOne);

//         assertEq(baseUriOne, ext.viewBaseURI(10));

//         ext.setBaseURI(batchId, baseUriTwo);
//         assertEq(baseUriTwo, ext.viewBaseURI(10));
//     }
// }
