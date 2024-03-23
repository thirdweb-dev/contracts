// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Airdrop } from "contracts/prebuilts/unaudited/airdrop/Airdrop.sol";

// Test imports
import { TWProxy } from "contracts/infra/TWProxy.sol";
import "../utils/BaseTest.sol";

contract AirdropTest is BaseTest {
    Airdrop internal airdrop;

    bytes32 private constant CONTENT_TYPEHASH_ERC20 =
        keccak256("AirdropContentERC20(address recipient,uint256 amount)");
    bytes32 private constant REQUEST_TYPEHASH_ERC20 =
        keccak256(
            "AirdropRequestERC20(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContentERC20[] contents)AirdropContentERC20(address recipient,uint256 amount)"
        );

    bytes32 private constant CONTENT_TYPEHASH_ERC721 =
        keccak256("AirdropContentERC721(address recipient,uint256 tokenId)");
    bytes32 private constant REQUEST_TYPEHASH_ERC721 =
        keccak256(
            "AirdropRequestERC721(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContentERC721[] contents)AirdropContentERC721(address recipient,uint256 tokenId)"
        );

    bytes32 private constant CONTENT_TYPEHASH_ERC1155 =
        keccak256("AirdropContentERC1155(address recipient,uint256 tokenId,uint256 amount)");
    bytes32 private constant REQUEST_TYPEHASH_ERC1155 =
        keccak256(
            "AirdropRequestERC1155(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContentERC1155[] contents)AirdropContentERC1155(address recipient,uint256 tokenId,uint256 amount)"
        );

    bytes32 private constant NAME_HASH = keccak256(bytes("Airdrop"));
    bytes32 private constant VERSION_HASH = keccak256(bytes("1"));
    bytes32 private constant TYPE_HASH_EIP712 =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 internal domainSeparator;

    function setUp() public override {
        super.setUp();

        address impl = address(new Airdrop());

        airdrop = Airdrop(payable(address(new TWProxy(impl, abi.encodeCall(Airdrop.initialize, (signer))))));

        domainSeparator = keccak256(
            abi.encode(TYPE_HASH_EIP712, NAME_HASH, VERSION_HASH, block.chainid, address(airdrop))
        );
    }

    function _getContentsERC20(uint256 length) internal pure returns (Airdrop.AirdropContentERC20[] memory contents) {
        contents = new Airdrop.AirdropContentERC20[](length);
        for (uint256 i = 0; i < length; i++) {
            contents[i].recipient = address(uint160(i + 10));
            contents[i].amount = i + 10;
        }
    }

    function _getContentsERC721(uint256 length) internal pure returns (Airdrop.AirdropContentERC721[] memory contents) {
        contents = new Airdrop.AirdropContentERC721[](length);
        for (uint256 i = 0; i < length; i++) {
            contents[i].recipient = address(uint160(i + 10));
            contents[i].tokenId = i;
        }
    }

    function _getContentsERC1155(
        uint256 length
    ) internal pure returns (Airdrop.AirdropContentERC1155[] memory contents) {
        contents = new Airdrop.AirdropContentERC1155[](length);
        for (uint256 i = 0; i < length; i++) {
            contents[i].recipient = address(uint160(i + 10));
            contents[i].tokenId = 0;
            contents[i].amount = i + 10;
        }
    }

    function _signReqERC20(
        Airdrop.AirdropRequestERC20 memory req,
        uint256 privateKey
    ) internal view returns (bytes memory signature) {
        bytes32[] memory contentHashes = new bytes32[](req.contents.length);
        for (uint i = 0; i < req.contents.length; i++) {
            contentHashes[i] = keccak256(
                abi.encode(CONTENT_TYPEHASH_ERC20, req.contents[i].recipient, req.contents[i].amount)
            );
        }
        bytes32 contentHash = keccak256(abi.encodePacked(contentHashes));

        bytes memory dataToHash;
        {
            dataToHash = abi.encode(
                REQUEST_TYPEHASH_ERC20,
                req.uid,
                req.tokenAddress,
                req.expirationTimestamp,
                contentHash
            );
        }

        {
            bytes32 _structHash = keccak256(dataToHash);
            bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, _structHash));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);

            signature = abi.encodePacked(r, s, v);
        }
    }

    function _signReqERC721(
        Airdrop.AirdropRequestERC721 memory req,
        uint256 privateKey
    ) internal view returns (bytes memory signature) {
        bytes32[] memory contentHashes = new bytes32[](req.contents.length);
        for (uint i = 0; i < req.contents.length; i++) {
            contentHashes[i] = keccak256(
                abi.encode(CONTENT_TYPEHASH_ERC721, req.contents[i].recipient, req.contents[i].tokenId)
            );
        }
        bytes32 contentHash = keccak256(abi.encodePacked(contentHashes));

        bytes memory dataToHash;
        {
            dataToHash = abi.encode(
                REQUEST_TYPEHASH_ERC721,
                req.uid,
                req.tokenAddress,
                req.expirationTimestamp,
                contentHash
            );
        }

        {
            bytes32 _structHash = keccak256(dataToHash);
            bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, _structHash));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);

            signature = abi.encodePacked(r, s, v);
        }
    }

    function _signReqERC1155(
        Airdrop.AirdropRequestERC1155 memory req,
        uint256 privateKey
    ) internal view returns (bytes memory signature) {
        bytes32[] memory contentHashes = new bytes32[](req.contents.length);
        for (uint i = 0; i < req.contents.length; i++) {
            contentHashes[i] = keccak256(
                abi.encode(
                    CONTENT_TYPEHASH_ERC1155,
                    req.contents[i].recipient,
                    req.contents[i].tokenId,
                    req.contents[i].amount
                )
            );
        }
        bytes32 contentHash = keccak256(abi.encodePacked(contentHashes));

        bytes memory dataToHash;
        {
            dataToHash = abi.encode(
                REQUEST_TYPEHASH_ERC1155,
                req.uid,
                req.tokenAddress,
                req.expirationTimestamp,
                contentHash
            );
        }

        {
            bytes32 _structHash = keccak256(dataToHash);
            bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, _structHash));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);

            signature = abi.encodePacked(r, s, v);
        }
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Push ERC20 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropPush_erc20() public {
        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContentERC20[] memory contents = _getContentsERC20(10);

        vm.prank(signer);

        airdrop.airdropERC20(address(erc20), contents);

        uint256 totalAmount;
        for (uint256 i = 0; i < contents.length; i++) {
            totalAmount += contents[i].amount;
            assertEq(erc20.balanceOf(contents[i].recipient), contents[i].amount);
        }
        assertEq(erc20.balanceOf(signer), 100 ether - totalAmount);
    }

    /*///////////////////////////////////////////////////////////////
                    Benchmark: Airdrop Signature ERC20 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropSignature_erc20() public {
        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContentERC20[] memory contents = _getContentsERC20(10);
        Airdrop.AirdropRequestERC20 memory req = Airdrop.AirdropRequestERC20({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc20),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC20(req, privateKey);

        vm.prank(signer);

        airdrop.airdropERC20WithSignature(req, signature);

        uint256 totalAmount;
        for (uint256 i = 0; i < contents.length; i++) {
            totalAmount += contents[i].amount;
            assertEq(erc20.balanceOf(contents[i].recipient), contents[i].amount);
        }
        assertEq(erc20.balanceOf(signer), 100 ether - totalAmount);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Claim ERC20 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropClaim_erc20() public {
        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRootAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));
        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        // set merkle root
        vm.prank(signer);
        airdrop.setMerkleRoot(address(erc20), root, true);

        // generate proof
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 5;

        vm.prank(receiver);

        airdrop.claimERC20(address(erc20), receiver, quantity, proofs);

        assertEq(erc20.balanceOf(receiver), quantity);
        assertEq(erc20.balanceOf(signer), 100 ether - quantity);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Push ERC721 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropPush_erc721() public {
        erc721.mint(signer, 100);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContentERC721[] memory contents = _getContentsERC721(10);

        vm.prank(signer);

        airdrop.airdropERC721(address(erc721), contents);

        for (uint256 i = 0; i < contents.length; i++) {
            assertEq(erc721.ownerOf(contents[i].tokenId), contents[i].recipient);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Benchmark: Airdrop Signature ERC721 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropSignature_erc721() public {
        erc721.mint(signer, 1000);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContentERC721[] memory contents = _getContentsERC721(10);
        Airdrop.AirdropRequestERC721 memory req = Airdrop.AirdropRequestERC721({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc721),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC721(req, privateKey);

        vm.prank(signer);

        airdrop.airdropERC721WithSignature(req, signature);

        for (uint256 i = 0; i < contents.length; i++) {
            assertEq(erc721.ownerOf(contents[i].tokenId), contents[i].recipient);
        }
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Claim ERC721 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropClaim_erc721() public {
        erc721.mint(signer, 100);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRootAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));
        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        // set merkle root
        vm.prank(signer);
        airdrop.setMerkleRoot(address(erc721), root, true);

        // generate proof
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 tokenId = 5;

        vm.prank(receiver);

        airdrop.claimERC721(address(erc721), receiver, tokenId, proofs);

        assertEq(erc721.ownerOf(tokenId), receiver);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Push ERC1155 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropPush_erc1155() public {
        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContentERC1155[] memory contents = _getContentsERC1155(10);

        vm.prank(signer);

        airdrop.airdropERC1155(address(erc1155), contents);

        for (uint256 i = 0; i < contents.length; i++) {
            assertEq(erc1155.balanceOf(contents[i].recipient, contents[i].tokenId), contents[i].amount);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Benchmark: Airdrop Signature ERC1155 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropSignature_erc115() public {
        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContentERC1155[] memory contents = _getContentsERC1155(10);
        Airdrop.AirdropRequestERC1155 memory req = Airdrop.AirdropRequestERC1155({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc1155),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC1155(req, privateKey);

        vm.prank(signer);

        airdrop.airdropERC1155WithSignature(req, signature);

        for (uint256 i = 0; i < contents.length; i++) {
            assertEq(erc1155.balanceOf(contents[i].recipient, contents[i].tokenId), contents[i].amount);
        }
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Claim ERC1155 
    //////////////////////////////////////////////////////////////*/

    function test_state_airdropClaim_erc1155() public {
        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRootAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));
        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        // set merkle root
        vm.prank(signer);
        airdrop.setMerkleRoot(address(erc1155), root, true);

        // generate proof
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 5;

        vm.prank(receiver);

        airdrop.claimERC1155(address(erc1155), receiver, 0, quantity, proofs);

        assertEq(erc1155.balanceOf(receiver, 0), quantity);
        assertEq(erc1155.balanceOf(signer, 0), 100 ether - quantity);
    }
}
