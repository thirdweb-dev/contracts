// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Airdrop } from "contracts/prebuilts/unaudited/airdrop/Airdrop.sol";

// Test imports
import { TWProxy } from "contracts/infra/TWProxy.sol";
import "../utils/BaseTest.sol";

contract AirdropBenchmarkTest is BaseTest {
    Airdrop internal airdrop;

    bytes32 private constant CONTENT_TYPEHASH_ERC20 = keccak256("AirdropContent20(address recipient,uint256 amount)");
    bytes32 private constant REQUEST_TYPEHASH_ERC20 =
        keccak256(
            "AirdropRequest20(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContent20[] contents)AirdropContent20(address recipient,uint256 amount)"
        );

    bytes32 private constant CONTENT_TYPEHASH_ERC721 =
        keccak256("AirdropContent721(address recipient,uint256 tokenId)");
    bytes32 private constant REQUEST_TYPEHASH_ERC721 =
        keccak256(
            "AirdropRequest721(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContent721[] contents)AirdropContent721(address recipient,uint256 tokenId)"
        );

    bytes32 private constant CONTENT_TYPEHASH_ERC1155 =
        keccak256("AirdropContent1155(address recipient,uint256 tokenId,uint256 amount)");
    bytes32 private constant REQUEST_TYPEHASH_ERC1155 =
        keccak256(
            "AirdropRequest1155(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContent1155[] contents)AirdropContent1155(address recipient,uint256 tokenId,uint256 amount)"
        );

    bytes32 private constant NAME_HASH = keccak256(bytes("Airdrop"));
    bytes32 private constant VERSION_HASH = keccak256(bytes("1"));
    bytes32 private constant TYPE_HASH_EIP712 =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 internal domainSeparator;

    function setUp() public override {
        super.setUp();

        address impl = address(new Airdrop());

        airdrop = Airdrop(address(new TWProxy(impl, abi.encodeCall(Airdrop.initialize, (signer)))));

        domainSeparator = keccak256(
            abi.encode(TYPE_HASH_EIP712, NAME_HASH, VERSION_HASH, block.chainid, address(airdrop))
        );
    }

    function _getContentsERC20(uint256 length) internal pure returns (Airdrop.AirdropContent20[] memory contents) {
        contents = new Airdrop.AirdropContent20[](length);
        for (uint256 i = 0; i < length; i++) {
            contents[i].recipient = address(uint160(i + 10));
            contents[i].amount = i + 10;
        }
    }

    function _getContentsERC721(uint256 length) internal pure returns (Airdrop.AirdropContent721[] memory contents) {
        contents = new Airdrop.AirdropContent721[](length);
        for (uint256 i = 0; i < length; i++) {
            contents[i].recipient = address(uint160(i + 10));
            contents[i].tokenId = i;
        }
    }

    function _getContentsERC1155(uint256 length) internal pure returns (Airdrop.AirdropContent1155[] memory contents) {
        contents = new Airdrop.AirdropContent1155[](length);
        for (uint256 i = 0; i < length; i++) {
            contents[i].recipient = address(uint160(i + 10));
            contents[i].tokenId = 0;
            contents[i].amount = i + 10;
        }
    }

    function _signReqERC20(
        Airdrop.AirdropRequest20 memory req,
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
        Airdrop.AirdropRequest721 memory req,
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
        Airdrop.AirdropRequest1155 memory req,
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

    function test_benchmark_airdropPush_erc20_10() public {
        vm.pauseGasMetering();

        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContent20[] memory contents = _getContentsERC20(10);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop20(address(erc20), contents);
    }

    function test_benchmark_airdropPush_erc20_100() public {
        vm.pauseGasMetering();

        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContent20[] memory contents = _getContentsERC20(100);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop20(address(erc20), contents);
    }

    function test_benchmark_airdropPush_erc20_1000() public {
        vm.pauseGasMetering();

        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContent20[] memory contents = _getContentsERC20(1000);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop20(address(erc20), contents);
    }

    /*///////////////////////////////////////////////////////////////
                    Benchmark: Airdrop Signature ERC20 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropSignature_erc20_10() public {
        vm.pauseGasMetering();

        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContent20[] memory contents = _getContentsERC20(10);
        Airdrop.AirdropRequest20 memory req = Airdrop.AirdropRequest20({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc20),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC20(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop20WithSignature(req, signature);
    }

    function test_benchmark_airdropSignature_erc20_100() public {
        vm.pauseGasMetering();

        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContent20[] memory contents = _getContentsERC20(100);
        Airdrop.AirdropRequest20 memory req = Airdrop.AirdropRequest20({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc20),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC20(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop20WithSignature(req, signature);
    }

    function test_benchmark_airdropSignature_erc20_1000() public {
        vm.pauseGasMetering();

        erc20.mint(signer, 100 ether);
        vm.prank(signer);
        erc20.approve(address(airdrop), 100 ether);

        Airdrop.AirdropContent20[] memory contents = _getContentsERC20(1000);
        Airdrop.AirdropRequest20 memory req = Airdrop.AirdropRequest20({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc20),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC20(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop20WithSignature(req, signature);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Claim ERC20 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropClaim_erc20() public {
        vm.pauseGasMetering();

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
        airdrop.setMerkleRoot(address(erc20), root);

        // generate proof
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 5;

        vm.prank(receiver);
        vm.resumeGasMetering();
        airdrop.claim20(address(erc20), receiver, quantity, proofs);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Push ERC721 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropPush_erc721_10() public {
        vm.pauseGasMetering();

        erc721.mint(signer, 100);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent721[] memory contents = _getContentsERC721(10);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop721(address(erc721), contents);
    }

    function test_benchmark_airdropPush_erc721_100() public {
        vm.pauseGasMetering();

        erc721.mint(signer, 100);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent721[] memory contents = _getContentsERC721(100);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop721(address(erc721), contents);
    }

    function test_benchmark_airdropPush_erc721_1000() public {
        vm.pauseGasMetering();

        erc721.mint(signer, 1000);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent721[] memory contents = _getContentsERC721(1000);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop721(address(erc721), contents);
    }

    /*///////////////////////////////////////////////////////////////
                    Benchmark: Airdrop Signature ERC721 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropSignature_erc721_10() public {
        vm.pauseGasMetering();

        erc721.mint(signer, 1000);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent721[] memory contents = _getContentsERC721(10);
        Airdrop.AirdropRequest721 memory req = Airdrop.AirdropRequest721({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc721),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC721(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop721WithSignature(req, signature);
    }

    function test_benchmark_airdropSignature_erc721_100() public {
        vm.pauseGasMetering();

        erc721.mint(signer, 1000);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent721[] memory contents = _getContentsERC721(100);
        Airdrop.AirdropRequest721 memory req = Airdrop.AirdropRequest721({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc721),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC721(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop721WithSignature(req, signature);
    }

    function test_benchmark_airdropSignature_erc721_1000() public {
        vm.pauseGasMetering();

        erc721.mint(signer, 1000);
        vm.prank(signer);
        erc721.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent721[] memory contents = _getContentsERC721(1000);
        Airdrop.AirdropRequest721 memory req = Airdrop.AirdropRequest721({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc721),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC721(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop721WithSignature(req, signature);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Claim ERC721 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropClaim_erc721() public {
        vm.pauseGasMetering();

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
        airdrop.setMerkleRoot(address(erc721), root);

        // generate proof
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 tokenId = 5;

        vm.prank(receiver);
        vm.resumeGasMetering();
        airdrop.claim721(address(erc721), receiver, tokenId, proofs);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Push ERC1155 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropPush_erc1155_10() public {
        vm.pauseGasMetering();

        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent1155[] memory contents = _getContentsERC1155(10);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop1155(address(erc1155), contents);
    }

    function test_benchmark_airdropPush_erc1155_100() public {
        vm.pauseGasMetering();

        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent1155[] memory contents = _getContentsERC1155(100);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop1155(address(erc1155), contents);
    }

    function test_benchmark_airdropPush_erc1155_1000() public {
        vm.pauseGasMetering();

        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent1155[] memory contents = _getContentsERC1155(1000);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop1155(address(erc1155), contents);
    }

    /*///////////////////////////////////////////////////////////////
                    Benchmark: Airdrop Signature ERC1155 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropSignature_erc115_10() public {
        vm.pauseGasMetering();

        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent1155[] memory contents = _getContentsERC1155(10);
        Airdrop.AirdropRequest1155 memory req = Airdrop.AirdropRequest1155({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc1155),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC1155(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop1155WithSignature(req, signature);
    }

    function test_benchmark_airdropSignature_erc115_100() public {
        vm.pauseGasMetering();

        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent1155[] memory contents = _getContentsERC1155(100);
        Airdrop.AirdropRequest1155 memory req = Airdrop.AirdropRequest1155({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc1155),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC1155(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop1155WithSignature(req, signature);
    }

    function test_benchmark_airdropSignature_erc115_1000() public {
        vm.pauseGasMetering();

        erc1155.mint(signer, 0, 100 ether);
        vm.prank(signer);
        erc1155.setApprovalForAll(address(airdrop), true);

        Airdrop.AirdropContent1155[] memory contents = _getContentsERC1155(1000);
        Airdrop.AirdropRequest1155 memory req = Airdrop.AirdropRequest1155({
            uid: bytes32(uint256(1)),
            tokenAddress: address(erc1155),
            expirationTimestamp: 1000,
            contents: contents
        });
        bytes memory signature = _signReqERC1155(req, privateKey);

        vm.prank(signer);
        vm.resumeGasMetering();
        airdrop.airdrop1155WithSignature(req, signature);
    }

    /*///////////////////////////////////////////////////////////////
                       Benchmark: Airdrop Claim ERC1155 
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropClaim_erc1155() public {
        vm.pauseGasMetering();

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
        airdrop.setMerkleRoot(address(erc1155), root);

        // generate proof
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 5;

        vm.prank(receiver);
        vm.resumeGasMetering();
        airdrop.claim1155(address(erc1155), receiver, 0, quantity, proofs);
    }
}
