// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { SignatureMintERC1155 } from "contracts/extension/SignatureMintERC1155.sol";

contract MySigMint1155 is SignatureMintERC1155 {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSignMintRequest(address) internal view override returns (bool) {
        return condition;
    }

    function mintWithSignature(
        MintRequest calldata req,
        bytes calldata signature
    ) external payable returns (address signer) {
        if (!_canSignMintRequest(msg.sender)) {
            revert("not authorized");
        }

        signer = _processRequest(req, signature);
    }
}

contract ExtensionSignatureMintERC1155 is DSTest, Test {
    MySigMint1155 internal ext;

    uint256 public privateKey = 1234;
    address public signer;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    MySigMint1155.MintRequest _mintrequest;
    bytes _signature;

    function setUp() public {
        ext = new MySigMint1155();

        signer = vm.addr(privateKey);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC1155"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(ext)));

        _mintrequest.to = address(1);
        _mintrequest.royaltyRecipient = address(2);
        _mintrequest.royaltyBps = 0;
        _mintrequest.primarySaleRecipient = address(2);
        _mintrequest.tokenId = 0;
        _mintrequest.uri = "ipfs://";
        _mintrequest.quantity = 1;
        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(0x111);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        MySigMint1155.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = bytes.concat(
            abi.encode(
                typehashMintRequest,
                _request.to,
                _request.royaltyRecipient,
                _request.royaltyBps,
                _request.primarySaleRecipient,
                _request.tokenId,
                keccak256(bytes(_request.uri))
            ),
            abi.encode(
                _request.quantity,
                _request.pricePerToken,
                _request.currency,
                _request.validityStartTimestamp,
                _request.validityEndTimestamp,
                _request.uid
            )
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function test_state_mintWithSignature() public {
        vm.warp(1000);
        ext.setCondition(true);
        vm.prank(signer);
        address recoveredSigner = ext.mintWithSignature(_mintrequest, _signature);

        assertEq(signer, recoveredSigner);
    }

    function test_revert_mintWithSignature_NotAuthorized() public {
        vm.expectRevert("not authorized");
        ext.mintWithSignature(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_InvalidReq() public {
        vm.warp(1000);
        ext.setCondition(true);

        vm.prank(signer);
        ext.mintWithSignature(_mintrequest, _signature);

        vm.expectRevert("Invalid request");
        ext.mintWithSignature(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_RequestExpired() public {
        vm.warp(3000);
        ext.setCondition(true);

        vm.prank(signer);
        vm.expectRevert("Request expired");
        ext.mintWithSignature(_mintrequest, _signature);
    }
}
