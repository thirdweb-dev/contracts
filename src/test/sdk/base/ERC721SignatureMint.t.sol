// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721SignatureMint } from "contracts/base/ERC721SignatureMint.sol";

contract BaseERC721SignatureMintTest is BaseUtilTest {
    ERC721SignatureMint internal base;
    using Strings for uint256;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    ERC721SignatureMint.MintRequest _mintrequest;
    bytes _signature;

    address recipient;

    function setUp() public override {
        super.setUp();
        vm.prank(signer);
        base = new ERC721SignatureMint(signer, NAME, SYMBOL, royaltyRecipient, royaltyBps, saleRecipient);

        recipient = address(0x123);
        erc20.mint(recipient, 1_000);
        vm.deal(recipient, 1_000);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC721"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(base)));

        _mintrequest.to = recipient;
        _mintrequest.royaltyRecipient = royaltyRecipient;
        _mintrequest.royaltyBps = royaltyBps;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.uri = "ipfs://";
        _mintrequest.quantity = 1;
        _mintrequest.pricePerToken = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        ERC721SignatureMint.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.royaltyRecipient,
            _request.royaltyBps,
            _request.primarySaleRecipient,
            keccak256(bytes(_request.uri)),
            _request.quantity,
            _request.pricePerToken,
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

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintWithSignature`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintWithSignature_ZeroPrice() public {
        vm.warp(1000);

        uint256 nextTokenId = base.nextTokenIdToMint();
        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        base.mintWithSignature(_mintrequest, _signature);

        assertEq(base.nextTokenIdToMint(), nextTokenId + _mintrequest.quantity);
        assertEq(base.tokenURI(nextTokenId), string(abi.encodePacked(_mintrequest.uri)));
        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(base.ownerOf(nextTokenId), recipient);
    }

    function test_state_mintWithSignature_NonZeroPrice_ERC20() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        erc20.approve(address(base), 1);

        uint256 nextTokenId = base.nextTokenIdToMint();
        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.prank(recipient);
        base.mintWithSignature(_mintrequest, _signature);

        assertEq(base.nextTokenIdToMint(), nextTokenId + _mintrequest.quantity);
        assertEq(base.tokenURI(nextTokenId), string(abi.encodePacked(_mintrequest.uri)));
        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(base.ownerOf(nextTokenId), recipient);
    }

    function test_state_mintWithSignature_NonZeroPrice_NativeToken() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        uint256 nextTokenId = base.nextTokenIdToMint();
        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.deal(recipient, 1);

        vm.prank(recipient);
        base.mintWithSignature{ value: 1 }(_mintrequest, _signature);

        assertEq(base.nextTokenIdToMint(), nextTokenId + _mintrequest.quantity);
        assertEq(base.tokenURI(nextTokenId), string(abi.encodePacked(_mintrequest.uri)));
        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(base.ownerOf(nextTokenId), recipient);
    }

    function test_revert_mintWithSignature_MustSendTotalPrice() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        vm.expectRevert("Invalid msg value");
        base.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_QuantityNotOne() public {
        vm.warp(1000);

        _mintrequest.quantity = 0;
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("quantiy must be 1");
        base.mintWithSignature(_mintrequest, _signature);
    }
}
