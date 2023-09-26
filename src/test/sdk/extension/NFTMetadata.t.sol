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

    function _canSetMetadata() internal view override returns (bool) {
        if (msg.sender == authorized) return true;
        return false;
    }

    function _canFreezeMetadata() internal view override returns (bool) {
        if (msg.sender == authorized) return true;
        return false;
    }

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return _getTokenURI(_tokenId);
    }

    function URIStatus() external view returns (bool) {
        return _URIFrozen;
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
        ext.freezeMetadata();
        string memory uri = "test";
        vm.expectRevert("NFTMetadata: metadata is frozen.");
        ext.setTokenURI(2, uri);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `freezeMetadata`
    //////////////////////////////////////////////////////////////*/

    function test_freezeTokenURI_state() public {
        ext.freezeMetadata();
        assertEq(ext.URIStatus(), true);
    }

    function test_freezeTokenURI_revert_notAuthorized() public {
        vm.startPrank(address(0x1));
        vm.expectRevert("NFTMetadata: not authorized to freeze metdata");
        ext.freezeMetadata();
    }
}
