// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC1155 is DropERC1155 {
    function collectPriceOnClaimHarness(
        uint256 _tokenId,
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) public payable {
        collectPriceOnClaim(_tokenId, _primarySaleRecipient, _quantityToClaim, _currency, _pricePerToken);
    }
}

contract DropERC1155Test_collectPrice is BaseTest {
    address private collectPrice_saleRecipient = address(0x010);
    address private collectPrice_royaltyRecipient = address(0x011);
    uint128 private collectPrice_royaltyBps = 1000;
    uint128 private collectPrice_platformFeeBps = 1000;
    address private collectPrice_platformFeeRecipient = address(0x012);
    uint256 private collectPrice_quantityToClaim = 1;
    uint256 private collectPrice_pricePerToken;
    address private collectPrice_currency;
    uint256 private collectPrice_msgValue;
    address private collectPrice_tokenSaleRecipient = address(0x111);

    address public dropImp;
    HarnessDropERC1155 public proxy;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC1155.initialize,
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
        );

        dropImp = address(new HarnessDropERC1155());
        proxy = HarnessDropERC1155(address(new TWProxy(dropImp, initializeData)));
    }

    modifier pricePerTokenZero() {
        collectPrice_pricePerToken = 0;
        _;
    }

    modifier pricePerTokenNotZero() {
        collectPrice_pricePerToken = 1 ether;
        _;
    }

    modifier msgValueNotZero() {
        collectPrice_msgValue = 1 ether;
        _;
    }

    modifier nativeCurrency() {
        collectPrice_currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        _;
    }

    modifier erc20Currency() {
        collectPrice_currency = address(erc20);
        erc20.mint(address(this), 1_000 ether);
        _;
    }

    modifier primarySaleRecipientZeroAddress() {
        saleRecipient = address(0);
        _;
    }

    modifier primarySaleRecipientNotZeroAddress() {
        saleRecipient = address(0x112);
        _;
    }

    modifier saleRecipientSet() {
        vm.prank(deployer);
        proxy.setSaleRecipientForToken(0, address(0x111));
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    function test_revert_msgValueNotZero() public nativeCurrency msgValueNotZero pricePerTokenZero {
        vm.expectRevert();
        proxy.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_msgValueZero_return() public nativeCurrency pricePerTokenZero {
        proxy.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_revert_priceValueMismatchNativeCurrency() public nativeCurrency pricePerTokenNotZero {
        vm.expectRevert();
        proxy.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_transferNativeCurrencyToSaleRecipient() public nativeCurrency pricePerTokenNotZero msgValueNotZero {
        uint256 balanceSaleRecipientBefore = address(saleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(platformFeeRecipient).balance;
        proxy.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = address(saleRecipient).balance;
        uint256 platformFeeRecipientAfter = address(platformFeeRecipient).balance;
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_msgValue - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferERC20ToSaleRecipient() public erc20Currency pricePerTokenNotZero {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(saleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(platformFeeRecipient);
        erc20.approve(address(proxy), collectPrice_pricePerToken);
        proxy.collectPriceOnClaimHarness(
            0,
            saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = erc20.balanceOf(saleRecipient);
        uint256 platformFeeRecipientAfter = erc20.balanceOf(platformFeeRecipient);
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_pricePerToken - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferNativeCurrencyToTokenIdSaleRecipient()
        public
        nativeCurrency
        pricePerTokenNotZero
        msgValueNotZero
        saleRecipientSet
        primarySaleRecipientZeroAddress
    {
        uint256 balanceSaleRecipientBefore = address(collectPrice_tokenSaleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(platformFeeRecipient).balance;
        proxy.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = address(collectPrice_tokenSaleRecipient).balance;
        uint256 platformFeeRecipientAfter = address(platformFeeRecipient).balance;
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_msgValue - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferERC20ToTokenIdSaleRecipient() public erc20Currency pricePerTokenNotZero saleRecipientSet {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(collectPrice_tokenSaleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(platformFeeRecipient);
        erc20.approve(address(proxy), collectPrice_pricePerToken);
        proxy.collectPriceOnClaimHarness(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = erc20.balanceOf(collectPrice_tokenSaleRecipient);
        uint256 platformFeeRecipientAfter = erc20.balanceOf(platformFeeRecipient);
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_pricePerToken - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferNativeCurrencyToPrimarySaleRecipient()
        public
        nativeCurrency
        pricePerTokenNotZero
        msgValueNotZero
    {
        uint256 balanceSaleRecipientBefore = address(saleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(platformFeeRecipient).balance;
        proxy.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = address(saleRecipient).balance;
        uint256 platformFeeRecipientAfter = address(platformFeeRecipient).balance;
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_msgValue - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferERC20ToPrimarySaleRecipient() public erc20Currency pricePerTokenNotZero {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(saleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(platformFeeRecipient);
        erc20.approve(address(proxy), collectPrice_pricePerToken);
        proxy.collectPriceOnClaimHarness(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = erc20.balanceOf(saleRecipient);
        uint256 platformFeeRecipientAfter = erc20.balanceOf(platformFeeRecipient);
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_pricePerToken - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }
}
