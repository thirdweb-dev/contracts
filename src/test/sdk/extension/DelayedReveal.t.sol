// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { DelayedReveal } from "contracts/extension/DelayedReveal.sol";

contract MyDelayedReveal is DelayedReveal {
    function setEncryptedData(uint256 _batchId, bytes memory _encryptedData) external {
        _setEncryptedData(_batchId, _encryptedData);
    }

    function reveal(uint256 identifier, bytes calldata key) external returns (string memory revealedURI) {}
}

contract ExtensionDelayedReveal is DSTest, Test {
    MyDelayedReveal internal ext;

    function setUp() public {
        ext = new MyDelayedReveal();
    }

    function test_state_setEncryptedData() public {
        string memory uriToEncrypt = "uri_string";
        bytes memory key = "key";

        bytes memory encryptedUri = ext.encryptDecrypt(bytes(uriToEncrypt), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(uriToEncrypt, key, block.chainid));

        bytes memory data = abi.encode(encryptedUri, provenanceHash);

        ext.setEncryptedData(0, data);

        assertEq(true, ext.isEncryptedBatch(0));
    }

    function test_state_getRevealURI() public {
        string memory uriToEncrypt = "uri_string";
        bytes memory key = "key";

        bytes memory encryptedUri = ext.encryptDecrypt(bytes(uriToEncrypt), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(uriToEncrypt, key, block.chainid));

        bytes memory data = abi.encode(encryptedUri, provenanceHash);

        ext.setEncryptedData(0, data);

        string memory revealedURI = ext.getRevealURI(0, key);

        assertEq(uriToEncrypt, revealedURI);
    }

    function test_revert_getRevealURI_IncorrectKey() public {
        string memory uriToEncrypt = "uri_string";
        bytes memory key = "key";
        bytes memory incorrectKey = "incorrect key";

        bytes memory encryptedUri = ext.encryptDecrypt(bytes(uriToEncrypt), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(uriToEncrypt, key, block.chainid));
        string memory incorrectURI = string(ext.encryptDecrypt(encryptedUri, incorrectKey));

        bytes memory data = abi.encode(encryptedUri, provenanceHash);

        ext.setEncryptedData(0, data);

        vm.expectRevert(
            abi.encodeWithSelector(
                DelayedReveal.DelayedRevealIncorrectResultHash.selector,
                provenanceHash,
                keccak256(abi.encodePacked(incorrectURI, incorrectKey, block.chainid))
            )
        );
        ext.getRevealURI(0, incorrectKey);
    }

    function test_revert_getRevealURI_NothingToReveal() public {
        string memory uriToEncrypt = "uri_string";
        bytes memory key = "key";

        bytes memory encryptedUri = ext.encryptDecrypt(bytes(uriToEncrypt), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(uriToEncrypt, key, block.chainid));

        bytes memory data = abi.encode(encryptedUri, provenanceHash);

        ext.setEncryptedData(0, data);
        assertEq(true, ext.isEncryptedBatch(0));

        ext.setEncryptedData(0, "");
        assertFalse(ext.isEncryptedBatch(0));

        vm.expectRevert(abi.encodeWithSelector(DelayedReveal.DelayedRevealNothingToReveal.selector));
        ext.getRevealURI(0, key);
    }
}
