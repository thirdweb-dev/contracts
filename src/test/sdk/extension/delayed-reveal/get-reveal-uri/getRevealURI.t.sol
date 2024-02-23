// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { DelayedReveal, IDelayedReveal } from "contracts/extension/DelayedReveal.sol";
import "../../ExtensionUtilTest.sol";

contract MyDelayedReveal is DelayedReveal {
    function setEncryptedData(uint256 _batchId, bytes memory _encryptedData) external {
        _setEncryptedData(_batchId, _encryptedData);
    }

    function reveal(uint256 identifier, bytes calldata key) external returns (string memory revealedURI) {}
}

contract DelayedReveal_GetRevealURI is ExtensionUtilTest {
    MyDelayedReveal internal ext;
    string internal originalURI;
    bytes internal encryptionKey;
    bytes internal encryptedURI;
    bytes internal encryptedData;
    uint256 internal batchId;
    bytes32 internal provenanceHash;

    function setUp() public override {
        super.setUp();

        ext = new MyDelayedReveal();
        originalURI = "ipfs://original";
        encryptionKey = "key123";
        batchId = 1;

        provenanceHash = keccak256(abi.encodePacked(originalURI, encryptionKey, block.chainid));
        encryptedURI = ext.encryptDecrypt(bytes(originalURI), encryptionKey);
        encryptedData = abi.encode(encryptedURI, provenanceHash);
    }

    function test_getRevealURI_encryptedDataNotSet() public {
        vm.expectRevert(abi.encodeWithSelector(DelayedReveal.DelayedRevealNothingToReveal.selector));
        ext.getRevealURI(batchId, encryptionKey);
    }

    modifier whenEncryptedDataIsSet() {
        ext.setEncryptedData(batchId, encryptedData);
        _;
    }

    function test_getRevealURI_incorrectKey() public whenEncryptedDataIsSet {
        bytes memory incorrectKey = "incorrect key";
        string memory incorrectURI = string(ext.encryptDecrypt(encryptedURI, incorrectKey));

        vm.expectRevert(
            abi.encodeWithSelector(
                DelayedReveal.DelayedRevealIncorrectResultHash.selector,
                provenanceHash,
                keccak256(abi.encodePacked(incorrectURI, incorrectKey, block.chainid))
            )
        );
        ext.getRevealURI(batchId, incorrectKey);
    }

    modifier whenCorrectKey() {
        _;
    }

    function test_getRevealURI() public whenEncryptedDataIsSet whenCorrectKey {
        string memory revealedURI = ext.getRevealURI(batchId, encryptionKey);

        assertEq(originalURI, revealedURI);
    }
}
