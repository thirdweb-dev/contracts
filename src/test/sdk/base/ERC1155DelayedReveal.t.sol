// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ERC1155DelayedReveal } from "contracts/base/ERC1155DelayedReveal.sol";
import { Strings } from "contracts/lib/Strings.sol";

contract ERC1155DelayedRevealTest is DSTest, Test {
    using Strings for uint256;

    // Target contract
    ERC1155DelayedReveal internal base;

    // Signers
    address internal admin;
    address internal nftHolder;

    // Lazy mitning args
    uint256 internal lazymintAmount = 10;
    string internal baseURI = "ipfs://";
    string internal placeholderURI = "placeholderURI://";
    bytes internal key = "key";

    function setUp() public {
        admin = address(0x123);
        nftHolder = address(0x456);

        vm.prank(admin);
        base = new ERC1155DelayedReveal(admin, "name", "symbol", admin, 0);

        bytes memory encryptedBaseURI = base.encryptDecrypt(bytes(baseURI), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(baseURI, key, block.chainid));
        vm.prank(admin);
        base.lazyMint(lazymintAmount, placeholderURI, abi.encode(encryptedBaseURI, provenanceHash));
    }

    function test_state_reveal() public {
        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < nextId; i += 1) {
            assertEq(base.uri(i), string(abi.encodePacked(placeholderURI, "0")));
        }

        vm.prank(admin);
        base.reveal(0, key);

        for (uint256 i = 0; i < nextId; i += 1) {
            assertEq(base.uri(i), string(abi.encodePacked(baseURI, i.toString())));
        }
    }

    function test_state_reveal_additionalBatch() public {
        uint256 nextIdBefore = base.nextTokenIdToMint();

        string memory newBaseURI = "ipfsNew://";
        string memory newPlaceholderURI = "placeholderURINew://";
        bytes memory newKey = "newkey";

        bytes memory encryptedBaseURI = base.encryptDecrypt(bytes(newBaseURI), newKey);
        bytes32 provenanceHash = keccak256(abi.encodePacked(newBaseURI, newKey, block.chainid));
        vm.prank(admin);
        base.lazyMint(lazymintAmount, newPlaceholderURI, abi.encode(encryptedBaseURI, provenanceHash));

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = nextIdBefore; i < nextId; i += 1) {
            assertEq(base.uri(i), string(abi.encodePacked(newPlaceholderURI, "0")));
        }

        vm.prank(admin);
        base.reveal(1, newKey);

        for (uint256 i = nextIdBefore; i < nextId; i += 1) {
            assertEq(base.uri(i), string(abi.encodePacked(newBaseURI, i.toString())));
        }
    }
}
