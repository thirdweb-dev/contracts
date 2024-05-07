// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC20SignatureMintVote } from "contracts/base/ERC20SignatureMintVote.sol";

contract BaseERC20SignatureMintVoteTest is BaseUtilTest {
    ERC20SignatureMintVote internal base;
    using Strings for uint256;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    ERC20SignatureMintVote.MintRequest _mintrequest;
    bytes _signature;

    address recipient;

    function setUp() public override {
        super.setUp();
        vm.prank(signer);
        base = new ERC20SignatureMintVote(signer, NAME, SYMBOL, saleRecipient);

        recipient = address(0x123);
        erc20.mint(recipient, 1_000 ether);
        vm.deal(recipient, 1_000 ether);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address primarySaleRecipient,uint256 quantity,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC20"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(base)));

        _mintrequest.to = recipient;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.quantity = 100 ether;
        _mintrequest.price = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        ERC20SignatureMintVote.MintRequest memory _request,
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

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintWithSignature`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintWithSignature_ZeroPrice() public {
        vm.warp(1000);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        address recoveredSigner = base.mintWithSignature(_mintrequest, _signature);

        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(signer, recoveredSigner);
    }

    function test_state_mintWithSignature_NonZeroPrice_ERC20() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        erc20.approve(address(base), _mintrequest.price);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);
        uint256 erc20BalanceOfRecipient = erc20.balanceOf(recipient);
        uint256 erc20BalanceOfSeller = erc20.balanceOf(saleRecipient);

        uint256 totalPrice = _mintrequest.price;

        vm.prank(recipient);
        base.mintWithSignature(_mintrequest, _signature);

        // check token balances
        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);

        // check erc20 currency balances
        assertEq(erc20.balanceOf(recipient), erc20BalanceOfRecipient - totalPrice);
        assertEq(erc20.balanceOf(saleRecipient), erc20BalanceOfSeller + totalPrice);
    }

    function test_state_mintWithSignature_NonZeroPrice_NativeToken() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);
        uint256 etherBalanceOfRecipient = recipient.balance;
        uint256 etherBalanceOfSeller = saleRecipient.balance;

        uint256 totalPrice = _mintrequest.price;

        vm.prank(recipient);
        base.mintWithSignature{ value: totalPrice }(_mintrequest, _signature);

        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);

        // check native-token balances
        assertEq(recipient.balance, etherBalanceOfRecipient - totalPrice);
        assertEq(saleRecipient.balance, etherBalanceOfSeller + totalPrice);
    }

    function test_revert_mintWithSignature_MustSendTotalPrice() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        vm.expectRevert("Must send total price.");
        base.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_MintingZeroTokens() public {
        vm.warp(1000);

        _mintrequest.quantity = 0;
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("Minting zero tokens.");
        base.mintWithSignature(_mintrequest, _signature);
    }
}
