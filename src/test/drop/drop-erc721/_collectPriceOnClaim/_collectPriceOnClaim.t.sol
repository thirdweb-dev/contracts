// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/prebuilts/drop/DropERC721.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC721 is DropERC721 {
    function collectionPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) public payable {
        _collectPriceOnClaim(_primarySaleRecipient, _quantityToClaim, _currency, _pricePerToken);
    }
}

contract DropERC721Test_collectPrice is BaseTest {
    address public dropImp;
    HarnessDropERC721 public proxy;

    address private collectPrice_saleRecipient = address(0x010);
    uint256 private collectPrice_quantityToClaim = 1;
    uint256 private collectPrice_pricePerToken;
    address private collectPrice_currency;
    uint256 private collectPrice_msgValue;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC721.initialize,
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

        dropImp = address(new HarnessDropERC721());
        proxy = HarnessDropERC721(address(new TWProxy(dropImp, initializeData)));
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

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    function test_revert_msgValueNotZero() public nativeCurrency msgValueNotZero pricePerTokenZero {
        vm.expectRevert();
        proxy.collectionPriceOnClaim{ value: collectPrice_msgValue }(
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_revert_priceValueMismatchNativeCurrency() public nativeCurrency pricePerTokenNotZero {
        vm.expectRevert();
        proxy.collectionPriceOnClaim{ value: collectPrice_msgValue }(
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_transferNativeCurrency() public nativeCurrency pricePerTokenNotZero msgValueNotZero {
        uint256 balanceSaleRecipientBefore = address(saleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(platformFeeRecipient).balance;
        proxy.collectionPriceOnClaim{ value: collectPrice_msgValue }(
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

    function test_transferERC20() public erc20Currency pricePerTokenNotZero {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(saleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(platformFeeRecipient);
        erc20.approve(address(proxy), collectPrice_pricePerToken);
        proxy.collectionPriceOnClaim(
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
}
