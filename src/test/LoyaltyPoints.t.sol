// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./utils/BaseTest.sol";
import "contracts/infra/TWProxy.sol";
import { Strings } from "contracts/lib/Strings.sol";
import { LoyaltyPoints } from "contracts/prebuilts/unaudited/loyalty/LoyaltyPoints.sol";

contract LoyaltyPointsTest is BaseTest {
    LoyaltyPoints internal loyaltyPoints;
    using Strings for uint256;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    LoyaltyPoints.MintRequest _mintrequest;
    bytes _signature;

    address recipient;

    function setUp() public override {
        super.setUp();

        address loyaltyPointsImpl = address(new LoyaltyPoints());

        vm.prank(signer);
        loyaltyPoints = LoyaltyPoints(
            address(
                new TWProxy(
                    loyaltyPointsImpl,
                    abi.encodeCall(
                        LoyaltyPoints.initialize,
                        (
                            signer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            platformFeeBps,
                            platformFeeRecipient
                        )
                    )
                )
            )
        );

        recipient = address(0x123);
        erc20.mint(recipient, 1_000);
        vm.deal(recipient, 1_000);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address primarySaleRecipient,uint256 quantity,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes(NAME));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(loyaltyPoints))
        );

        _mintrequest.to = recipient;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.quantity = 1 ether;
        _mintrequest.price = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        LoyaltyPoints.MintRequest memory _request,
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
                        Unit tests: `mintTo`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintTo() public {
        uint256 amount = 1 ether;

        uint256 currentTotalSupply = loyaltyPoints.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyPoints.balanceOf(recipient);

        vm.prank(signer);
        loyaltyPoints.mintTo(recipient, amount);

        assertEq(loyaltyPoints.totalSupply(), currentTotalSupply + amount);
        assertEq(loyaltyPoints.balanceOf(recipient), currentBalanceOfRecipient + amount);

        assertEq(loyaltyPoints.getTotalMintedInLifetime(recipient), amount);

        vm.prank(signer);
        loyaltyPoints.mintTo(recipient, amount);
        assertEq(loyaltyPoints.getTotalMintedInLifetime(recipient), amount * 2);

        vm.prank(recipient);
        loyaltyPoints.cancel(recipient, amount);
        assertEq(loyaltyPoints.getTotalMintedInLifetime(recipient), amount * 2);

        vm.prank(signer);
        loyaltyPoints.revoke(recipient, amount);
        assertEq(loyaltyPoints.getTotalMintedInLifetime(recipient), amount * 2);
    }

    /*///////////////////////////////////////////////////////////////
                    Unit tests: cancel / revoke loyalty
    //////////////////////////////////////////////////////////////*/

    function test_state_cancelLoyalty() public {
        uint256 amount = 10 ether;

        vm.prank(signer);
        loyaltyPoints.mintTo(recipient, amount);

        assertEq(loyaltyPoints.balanceOf(recipient), amount);

        uint256 amountToCancel = 1 ether;

        vm.prank(recipient);
        loyaltyPoints.approve(signer, amountToCancel);

        vm.prank(signer);
        loyaltyPoints.cancel(recipient, amountToCancel);
        assertEq(loyaltyPoints.balanceOf(recipient), amount - amountToCancel);
    }

    function test_state_revokeLoyalty() public {
        uint256 amount = 10 ether;

        vm.prank(signer);
        loyaltyPoints.mintTo(recipient, amount);

        assertEq(loyaltyPoints.balanceOf(recipient), amount);

        address burner = address(0x123456);
        vm.prank(signer);
        loyaltyPoints.grantRole(keccak256("REVOKE_ROLE"), burner);

        vm.prank(signer);
        loyaltyPoints.renounceRole(keccak256("REVOKE_ROLE"), signer);

        uint256 amountToRevoke = 1 ether;

        vm.expectRevert();
        vm.prank(signer);
        loyaltyPoints.revoke(recipient, amountToRevoke);

        vm.prank(burner);
        loyaltyPoints.revoke(recipient, amountToRevoke);
        assertEq(loyaltyPoints.balanceOf(recipient), amount - amountToRevoke);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintWithSignature`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintWithSignature_ZeroPrice() public {
        vm.warp(1000);

        uint256 currentTotalSupply = loyaltyPoints.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyPoints.balanceOf(recipient);

        loyaltyPoints.mintWithSignature(_mintrequest, _signature);

        assertEq(loyaltyPoints.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(loyaltyPoints.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
    }

    function test_state_mintWithSignature_NonZeroPrice_ERC20() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        erc20.approve(address(loyaltyPoints), 1);

        uint256 currentTotalSupply = loyaltyPoints.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyPoints.balanceOf(recipient);
        uint256 currentCurrencyBalOfRecipient = erc20.balanceOf(recipient);

        vm.prank(recipient);
        loyaltyPoints.mintWithSignature(_mintrequest, _signature);

        assertEq(loyaltyPoints.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(loyaltyPoints.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(erc20.balanceOf(recipient), currentCurrencyBalOfRecipient - _mintrequest.price);
    }

    function test_state_mintWithSignature_NonZeroPrice_NativeToken() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        uint256 currentTotalSupply = loyaltyPoints.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyPoints.balanceOf(recipient);

        vm.deal(recipient, 1);
        uint256 currentCurrencyBalOfRecipient = recipient.balance;

        vm.prank(recipient);
        loyaltyPoints.mintWithSignature{ value: 1 }(_mintrequest, _signature);

        assertEq(loyaltyPoints.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(loyaltyPoints.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(recipient.balance, currentCurrencyBalOfRecipient - _mintrequest.price);
    }

    function test_revert_mintWithSignature_InvalidMsgValue() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        vm.expectRevert("Invalid msg value");
        loyaltyPoints.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_ZeroQty() public {
        vm.warp(1000);

        _mintrequest.quantity = 0;
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("Minting zero qty");
        loyaltyPoints.mintWithSignature(_mintrequest, _signature);
    }
}
