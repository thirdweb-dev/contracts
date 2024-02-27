// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721DelayedReveal, BatchMintMetadata } from "contracts/base/ERC721DelayedReveal.sol";

contract BaseERC721DelayedRevealTest is BaseUtilTest {
    ERC721DelayedReveal internal base;
    using Strings for uint256;

    function setUp() public override {
        vm.prank(deployer);
        base = new ERC721DelayedReveal(deployer, NAME, SYMBOL, royaltyRecipient, royaltyBps);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `lazyMint`
    //////////////////////////////////////////////////////////////*/

    function test_state_lazyMint_noEncryptedURI() public {
        uint256 _amount = 100;
        string memory _baseURIForTokens = "baseURI/";
        bytes memory _encryptedBaseURI = "";

        uint256 nextTokenId = base.nextTokenIdToMint();

        vm.startPrank(deployer);
        uint256 batchId = base.lazyMint(_amount, _baseURIForTokens, _encryptedBaseURI);

        assertEq(nextTokenId + _amount, base.nextTokenIdToMint());
        assertEq(nextTokenId + _amount, batchId);

        for (uint256 i = 0; i < _amount; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURIForTokens, i.toString())));
        }

        vm.stopPrank();
    }

    function test_state_lazyMint_withEncryptedURI() public {
        uint256 _amount = 100;
        string memory _baseURIForTokens = "baseURI/";
        string memory secretURI = "secretURI/";
        bytes memory key = "key";
        bytes memory _encryptedBaseURI = base.encryptDecrypt(bytes(secretURI), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(secretURI, key, block.chainid));

        uint256 nextTokenId = base.nextTokenIdToMint();

        vm.startPrank(deployer);
        uint256 batchId = base.lazyMint(_amount, _baseURIForTokens, abi.encode(_encryptedBaseURI, provenanceHash));

        assertEq(nextTokenId + _amount, base.nextTokenIdToMint());
        assertEq(nextTokenId + _amount, batchId);

        for (uint256 i = 0; i < _amount; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURIForTokens, "0")));
        }

        vm.stopPrank();
    }

    function test_revert_lazyMint_URIForNonExistentId() public {
        uint256 _amount = 100;
        string memory _baseURIForTokens = "baseURI/";

        bytes memory key = "key";
        string memory secretURI = "secretURI/";
        bytes memory _encryptedBaseURI = base.encryptDecrypt(bytes(secretURI), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(secretURI, key, block.chainid));

        vm.startPrank(deployer);
        base.lazyMint(_amount, _baseURIForTokens, abi.encode(_encryptedBaseURI, provenanceHash));

        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidTokenId.selector, 100));
        base.tokenURI(100);

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `reveal`
    //////////////////////////////////////////////////////////////*/

    function test_state_reveal() public {
        uint256 _amount = 100;
        string memory _tempURIForTokens = "tempURI/";
        string memory _baseURIForTokens = "baseURI/";
        bytes memory key = "key";
        bytes memory _encryptedBaseURI = base.encryptDecrypt(bytes(_baseURIForTokens), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(_baseURIForTokens, key, block.chainid));

        vm.startPrank(deployer);
        base.lazyMint(_amount, _tempURIForTokens, abi.encode(_encryptedBaseURI, provenanceHash));

        for (uint256 i = 0; i < _amount; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_tempURIForTokens, "0")));
        }

        base.reveal(0, "key");

        for (uint256 i = 0; i < _amount; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURIForTokens, i.toString())));
        }

        vm.stopPrank();
    }

    function test_revert_reveal_NotAuthorized() public {
        uint256 _amount = 100;
        string memory _tempURIForTokens = "tempURI/";
        string memory _baseURIForTokens = "baseURI/";
        bytes memory key = "key";
        bytes memory _encryptedBaseURI = base.encryptDecrypt(bytes(_baseURIForTokens), key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(_baseURIForTokens, key, block.chainid));

        vm.prank(deployer);
        base.lazyMint(_amount, _tempURIForTokens, abi.encode(_encryptedBaseURI, provenanceHash));

        for (uint256 i = 0; i < _amount; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_tempURIForTokens, "0")));
        }

        vm.prank(address(0x345));
        vm.expectRevert("Not authorized");
        base.reveal(0, "key");
    }
}
