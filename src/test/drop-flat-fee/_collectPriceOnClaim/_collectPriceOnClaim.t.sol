// <ai_context>
// Unit tests for the internal _collectPriceOnClaim function in DropERC721FlatFee contract.
// Tests price collection and transfers, with flat fee mode.
// Adapted to verify fixed flat fee transfers and reverts if totalPrice < flatFee.
// </ai_context>

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721FlatFee } from "contracts/prebuilts/drop/DropERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract DropERC721FlatFeeHarness is DropERC721FlatFee {
    function collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) external payable {
        _collectPriceOnClaim(_primarySaleRecipient, _quantityToClaim, _currency, _pricePerToken);
    }
}

contract DropERC721FlatFeeTest_collectPrice is BaseTest {
    DropERC721FlatFeeHarness public drop;

    address private dropImpl;

    address private currency;
    address private primarySaleRecipient;
    uint256 private msgValue;
    uint256 private pricePerToken;
    uint256 private qty = 1;

    function setUp() public override {
        super.setUp();
        dropImpl = address(new DropERC721FlatFeeHarness());
        vm.prank(deployer);
        drop = DropERC721FlatFeeHarness(
            address(
                new TWProxy(
                    dropImpl,
                    abi.encodeCall(
                        DropERC721FlatFee.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps,
                            platformFeeBps,
                            platformFeeRecipient
                        )
                    )
                )
            )
        );
        // Set to flat fee mode
        vm.prank(deployer);
        drop.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);
        vm.prank(deployer);
        drop.setFlatPlatformFeeInfo(platformFeeRecipient, 0.1 ether);
    }

    modifier pricePerTokenZero() {
        _;
    }

    modifier pricePerTokenNotZero() {
        pricePerToken = 1 ether;
        _;
    }

    modifier msgValueZero() {
        _;
    }

    modifier msgValueNotZero() {
        msgValue = 1 ether;
        _;
    }

    modifier valuePriceMismatch() {
        msgValue = 1 ether;
        pricePerToken = 2 ether;
        _;
    }

    modifier primarySaleRecipientZeroAddress() {
        primarySaleRecipient = address(0);
        _;
    }

    modifier primarySaleRecipientNotZeroAddress() {
        primarySaleRecipient = address(0x0999);
        _;
    }

    modifier currencyNativeToken() {
        currency = NATIVE_TOKEN;
        _;
    }

    modifier currencyNotNativeToken() {
        currency = address(erc20);
        _;
    }

    function test_revert_pricePerTokenZeroMsgValueNotZero() public pricePerTokenZero msgValueNotZero {
        vm.expectRevert("!Value");
        drop.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    function test_revert_nativeCurrencyValuePriceMismatch() public currencyNativeToken valuePriceMismatch {
        vm.expectRevert(bytes("!V"));
        drop.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    function test_revert_erc20ValuePriceMismatch() public currencyNotNativeToken valuePriceMismatch {
        vm.expectRevert(bytes("!V"));
        drop.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    function test_state_nativeCurrency() public currencyNativeToken pricePerTokenNotZero msgValueNotZero primarySaleRecipientNotZeroAddress {
        uint256 beforeBalancePrimarySaleRecipient = address(primarySaleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(platformFeeRecipient).balance;

        drop.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = address(primarySaleRecipient).balance;
        uint256 platformFeeRecipientAfter = address(platformFeeRecipient).balance;

        uint256 platformFees = 0.1 ether; // flat fee
        uint256 primarySaleRecipientVal = msgValue - platformFees;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, platformFees);
    }

    function test_revert_totalPriceLessThanFlatFee() public currencyNativeToken pricePerTokenNotZero {
        pricePerToken = 0.05 ether;
        msgValue = 0.05 ether;
        vm.expectRevert("price less than platform fee");
        drop.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    // Other tests similar, adapted for flat fee (no defaultFee, only platform flat and primary)
    // ...
}