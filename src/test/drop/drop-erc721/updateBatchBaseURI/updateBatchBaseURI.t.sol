// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, BatchMintMetadata, Permissions } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports

import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC721Test_updateBatchBaseURI is BaseTest {
    using Strings for uint256;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    DropERC721 public drop;

    bytes private updateBatch_data;
    string private updateBatch_baseURI;
    string private updateBatch_newBaseURI;
    uint256 private updateBatch_amount;
    bytes private updateBatch_encryptedURI;
    bytes32 private updateBatch_provenanceHash;
    string private updateBatch_revealedURI;
    bytes private updateBatch_key;
    address private unauthorized = address(0x123);

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
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

    modifier lazyMintEncrypted() {
        updateBatch_amount = 10;
        updateBatch_baseURI = "ipfs://";
        updateBatch_revealedURI = "ipfs://revealed";
        updateBatch_key = "key";
        updateBatch_encryptedURI = drop.encryptDecrypt(bytes(updateBatch_revealedURI), updateBatch_key);
        updateBatch_provenanceHash = keccak256(
            abi.encodePacked(updateBatch_revealedURI, updateBatch_key, block.chainid)
        );
        updateBatch_data = abi.encode(updateBatch_encryptedURI, updateBatch_provenanceHash);
        vm.prank(deployer);
        drop.lazyMint(updateBatch_amount, updateBatch_baseURI, updateBatch_data);
        _;
    }

    modifier lazyMintUnEncryptedEmptyBaseURI() {
        updateBatch_amount = 10;
        updateBatch_baseURI = "";
        vm.prank(deployer);
        drop.lazyMint(updateBatch_amount, updateBatch_baseURI, updateBatch_data);
        _;
    }

    modifier lazyMintUnEncryptedRegularBaseURI() {
        updateBatch_amount = 10;
        updateBatch_baseURI = "ipfs://";
        vm.prank(deployer);
        drop.lazyMint(updateBatch_amount, updateBatch_baseURI, updateBatch_data);
        _;
    }

    modifier batchFrozen() {
        drop.freezeBatchBaseURI(0);
        _;
    }

    function test_revert_NoMetadataRole() public callerWithoutMetadataRole {
        bytes32 role = keccak256("METADATA_ROLE");
        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, unauthorized, role)
        );
        drop.updateBatchBaseURI(0, updateBatch_newBaseURI);
    }

    function test_revert_EncryptedBatch() public lazyMintEncrypted callerWithMetadataRole {
        vm.expectRevert("Encrypted batch");
        drop.updateBatchBaseURI(0, updateBatch_newBaseURI);
    }

    function test_revert_FrozenBatch() public lazyMintUnEncryptedRegularBaseURI callerWithMetadataRole batchFrozen {
        vm.expectRevert(
            abi.encodeWithSelector(BatchMintMetadata.BatchMintMetadataFrozen.selector, drop.getBatchIdAtIndex(0))
        );
        drop.updateBatchBaseURI(0, updateBatch_newBaseURI);
    }

    function test_state() public lazyMintUnEncryptedRegularBaseURI callerWithMetadataRole {
        drop.updateBatchBaseURI(0, updateBatch_newBaseURI);
        for (uint256 i = 0; i < updateBatch_amount; i += 1) {
            string memory uri = drop.tokenURI(i);
            assertEq(uri, string(abi.encodePacked(updateBatch_newBaseURI, i.toString())));
        }
    }

    function test_event() public lazyMintUnEncryptedRegularBaseURI callerWithMetadataRole {
        vm.expectEmit(false, false, false, false);
        emit BatchMetadataUpdate(0, 10);
        drop.updateBatchBaseURI(0, updateBatch_newBaseURI);
    }
}
