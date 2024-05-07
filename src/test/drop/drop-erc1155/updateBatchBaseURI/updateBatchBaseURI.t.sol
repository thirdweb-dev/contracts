// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155, BatchMintMetadata } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports

import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC1155Test_updateBatchBaseURI is BaseTest {
    using Strings for uint256;

    event MetadataFrozen();

    DropERC1155 public drop;

    address private unauthorized = address(0x123);

    bytes private emptyEncodedBytes = abi.encode("", "");
    string private updatedBaseURI = "ipfs://";

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerWithoutMetadataRole() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerWithMetadataRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier lazyMint() {
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        _;
    }

    modifier lazyMintEmptyUri() {
        vm.prank(deployer);
        drop.lazyMint(100, "", emptyEncodedBytes);
        _;
    }

    modifier batchFrozen() {
        vm.prank(deployer);
        drop.freezeBatchBaseURI(0);
        _;
    }

    function test_revert_NoMetadataRole() public lazyMint callerWithoutMetadataRole {
        bytes32 role = keccak256("METADATA_ROLE");
        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, unauthorized, role)
        );
        drop.updateBatchBaseURI(0, updatedBaseURI);
    }

    function test_revert_IndexTooHigh() public lazyMint callerWithMetadataRole {
        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidBatchId.selector, 1));
        drop.updateBatchBaseURI(1, updatedBaseURI);
    }

    function test_revert_BatchFrozen() public lazyMint batchFrozen callerWithMetadataRole {
        vm.expectRevert(
            abi.encodeWithSelector(BatchMintMetadata.BatchMintMetadataFrozen.selector, drop.getBatchIdAtIndex(0))
        );
        drop.updateBatchBaseURI(0, updatedBaseURI);
    }

    function test_state() public lazyMint callerWithMetadataRole {
        drop.updateBatchBaseURI(0, updatedBaseURI);
        string memory newBaseURI = drop.uri(0);
        console.log("newBaseURI: %s", newBaseURI);
        assertEq(newBaseURI, string(abi.encodePacked(updatedBaseURI, "0")));
    }

    function test_event() public lazyMint callerWithMetadataRole {
        vm.expectEmit(false, false, false, false);
        emit BatchMetadataUpdate(0, 100);
        drop.updateBatchBaseURI(0, updatedBaseURI);
    }
}
