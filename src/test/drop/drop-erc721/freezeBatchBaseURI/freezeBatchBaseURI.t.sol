// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, BatchMintMetadata } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract DropERC721Test_freezeBatchBaseURI is BaseTest {
    event MetadataFrozen();

    DropERC721 public drop;

    bytes private freeze_data;
    string private freeze_baseURI;
    uint256 private freeze_amount;
    bytes private freeze_encryptedURI;
    bytes32 private freeze_provenanceHash;
    string private freeze_revealedURI;
    bytes private freeze_key;
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
        freeze_amount = 10;
        freeze_baseURI = "ipfs://";
        freeze_revealedURI = "ipfs://revealed";
        freeze_key = "key";
        freeze_encryptedURI = drop.encryptDecrypt(bytes(freeze_revealedURI), freeze_key);
        freeze_provenanceHash = keccak256(abi.encodePacked(freeze_revealedURI, freeze_key, block.chainid));
        freeze_data = abi.encode(freeze_encryptedURI, freeze_provenanceHash);
        vm.prank(deployer);
        drop.lazyMint(freeze_amount, freeze_baseURI, freeze_data);
        _;
    }

    modifier lazyMintUnEncryptedEmptyBaseURI() {
        freeze_amount = 10;
        freeze_baseURI = "";
        vm.prank(deployer);
        drop.lazyMint(freeze_amount, freeze_baseURI, freeze_data);
        _;
    }

    modifier lazyMintUnEncryptedRegularBaseURI() {
        freeze_amount = 10;
        freeze_baseURI = "ipfs://";
        vm.prank(deployer);
        drop.lazyMint(freeze_amount, freeze_baseURI, freeze_data);
        _;
    }

    function test_revert_NoMetadataRole() public callerWithoutMetadataRole {
        bytes32 role = keccak256("METADATA_ROLE");
        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, unauthorized, role)
        );
        drop.freezeBatchBaseURI(0);
    }

    function test_revert_EncryptedBatch() public lazyMintEncrypted callerWithMetadataRole {
        vm.expectRevert("Encrypted batch");
        drop.freezeBatchBaseURI(0);
    }

    function test_revert_EmptyBaseURI() public lazyMintUnEncryptedEmptyBaseURI callerWithMetadataRole {
        vm.expectRevert(
            abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidBatchId.selector, drop.getBatchIdAtIndex(0))
        );
        drop.freezeBatchBaseURI(0);
    }

    function test_state() public lazyMintUnEncryptedRegularBaseURI callerWithMetadataRole {
        uint256 batchId = drop.getBatchIdAtIndex(0);
        drop.freezeBatchBaseURI(0);
        assertEq(drop.batchFrozen(batchId), true);
    }

    function test_event() public lazyMintUnEncryptedRegularBaseURI callerWithMetadataRole {
        vm.expectEmit(false, false, false, false);
        emit MetadataFrozen();
        drop.freezeBatchBaseURI(0);
    }
}
