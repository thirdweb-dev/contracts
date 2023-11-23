// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { SignatureMintERC20 } from "contracts/extension/SignatureMintERC20.sol";

contract MySigMint20 is SignatureMintERC20 {
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

contract ExtensionSignatureMintERC20 is DSTest, Test {
    MySigMint20 internal ext;

    uint256 public privateKey = 1234;
    address public signer;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    MySigMint20.MintRequest _mintrequest;
    bytes _signature;

    function setUp() public {
        ext = new MySigMint20();

        signer = vm.addr(privateKey);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address primarySaleRecipient,uint256 quantity,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC20"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(ext)));

        _mintrequest.to = address(1);
        _mintrequest.primarySaleRecipient = address(2);
        _mintrequest.quantity = 1;
        _mintrequest.price = 1;
        _mintrequest.currency = address(0x111);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        MySigMint20.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.primarySaleRecipient,
            _request.quantity,
            _request.price,
            _request.currency,
            _request.validityStartTimestamp,
            _request.validityEndTimestamp,
            _request.uid
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
