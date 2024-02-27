// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, BatchMintMetadata, DelayedReveal } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports

import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC721Test_reveal is BaseTest {
    using Strings for uint256;

    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    DropERC721 public drop;

    bytes private reveal_data;
    string private reveal_baseURI;
    uint256 private reveal_amount;
    bytes private reveal_encryptedURI;
    bytes32 private reveal_provenanceHash;
    string private reveal_revealedURI;
    uint256 private reveal_index;
    bytes private reveal_key;
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

    modifier validIndex() {
        reveal_index = 0;
        _;
    }

    modifier invalidKey() {
        reveal_key = "invalidKey";
        _;
    }

    modifier invalidIndex() {
        reveal_index = 1;
        _;
    }

    modifier lazyMintEncrypted() {
        reveal_amount = 10;
        reveal_baseURI = "ipfs://";
        reveal_revealedURI = "ipfs://revealed";
        reveal_key = "key";
        reveal_encryptedURI = drop.encryptDecrypt(bytes(reveal_revealedURI), reveal_key);
        reveal_provenanceHash = keccak256(abi.encodePacked(reveal_revealedURI, reveal_key, block.chainid));
        reveal_data = abi.encode(reveal_encryptedURI, reveal_provenanceHash);
        vm.prank(deployer);
        drop.lazyMint(reveal_amount, reveal_baseURI, reveal_data);
        _;
    }

    modifier lazyMintUnEncrypted() {
        reveal_amount = 10;
        reveal_baseURI = "ipfs://";
        vm.prank(deployer);
        drop.lazyMint(reveal_amount, reveal_baseURI, reveal_data);
        _;
    }

    function test_revert_NoMetadataRole() public callerWithoutMetadataRole {
        bytes32 role = keccak256("METADATA_ROLE");

        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, unauthorized, role)
        );
        drop.reveal(reveal_index, reveal_key);
    }

    function test_state() public validIndex lazyMintEncrypted callerWithMetadataRole {
        for (uint256 i = 0; i < reveal_amount; i += 1) {
            string memory uri = drop.tokenURI(i);
            assertEq(uri, string(abi.encodePacked(reveal_baseURI, "0")));
        }

        string memory revealedURI = drop.reveal(reveal_index, reveal_key);
        assertEq(revealedURI, string(reveal_revealedURI));

        for (uint256 i = 0; i < reveal_amount; i += 1) {
            string memory uri = drop.tokenURI(i);
            assertEq(uri, string(abi.encodePacked(reveal_revealedURI, i.toString())));
        }

        assertEq(drop.encryptedData(reveal_index), "");
    }

    function test_event() public validIndex lazyMintEncrypted callerWithMetadataRole {
        vm.expectEmit();
        emit TokenURIRevealed(reveal_index, reveal_revealedURI);
        drop.reveal(reveal_index, reveal_key);
    }

    function test_revert_InvalidIndex() public invalidIndex lazyMintEncrypted callerWithMetadataRole {
        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidBatchId.selector, reveal_index));
        drop.reveal(reveal_index, reveal_key);
    }

    function test_revert_InvalidKey() public validIndex lazyMintEncrypted invalidKey callerWithMetadataRole {
        string memory incorrectURI = string(drop.encryptDecrypt(reveal_encryptedURI, reveal_key));

        vm.expectRevert(
            abi.encodeWithSelector(
                DelayedReveal.DelayedRevealIncorrectResultHash.selector,
                reveal_provenanceHash,
                keccak256(abi.encodePacked(incorrectURI, reveal_key, block.chainid))
            )
        );
        drop.reveal(reveal_index, reveal_key);
    }

    function test_revert_NoEncryptedData() public validIndex lazyMintUnEncrypted callerWithMetadataRole {
        vm.expectRevert(abi.encodeWithSelector(DelayedReveal.DelayedRevealNothingToReveal.selector));
        drop.reveal(reveal_index, reveal_key);
    }
}
