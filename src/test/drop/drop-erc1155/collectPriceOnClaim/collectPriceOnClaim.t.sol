// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

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

    function initializeHarness(
        address _defaultAdmin,
        string memory _contractURI,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _metadataRole = keccak256("METADATA_ROLE");

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_metadataRole, _defaultAdmin);
        _setRoleAdmin(_metadataRole, _metadataRole);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);
    }
}

contract DropERC1155Test_collectPrice is BaseTest {
    using StringsUpgradeable for uint256;

    HarnessDropERC1155 public dropImp;

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

    function setUp() public override {
        super.setUp();

        dropImp = new HarnessDropERC1155();
        dropImp.initializeHarness(
            deployer,
            CONTRACT_URI,
            collectPrice_saleRecipient,
            collectPrice_royaltyRecipient,
            collectPrice_royaltyBps,
            collectPrice_platformFeeBps,
            collectPrice_platformFeeRecipient
        );
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
        collectPrice_saleRecipient = address(0);
        _;
    }

    modifier primarySaleRecipientNotZeroAddress() {
        collectPrice_saleRecipient = address(0x112);
        _;
    }

    modifier saleRecipientSet() {
        vm.prank(deployer);
        dropImp.setSaleRecipientForToken(0, address(0x111));
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    function test_revert_msgValueNotZero() public nativeCurrency msgValueNotZero pricePerTokenZero {
        vm.expectRevert();
        dropImp.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_msgValueZero_return() public nativeCurrency pricePerTokenZero {
        dropImp.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_revert_priceValueMismatchNativeCurrency() public nativeCurrency pricePerTokenNotZero {
        vm.expectRevert();
        dropImp.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_transferNativeCurrencyToSaleRecipient() public nativeCurrency pricePerTokenNotZero msgValueNotZero {
        uint256 balanceSaleRecipientBefore = address(collectPrice_saleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(collectPrice_platformFeeRecipient).balance;
        dropImp.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = address(collectPrice_saleRecipient).balance;
        uint256 platformFeeRecipientAfter = address(collectPrice_platformFeeRecipient).balance;
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * collectPrice_platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_msgValue - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferERC20ToSaleRecipient() public erc20Currency pricePerTokenNotZero {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(collectPrice_saleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(collectPrice_platformFeeRecipient);
        erc20.approve(address(dropImp), collectPrice_pricePerToken);
        dropImp.collectPriceOnClaimHarness(
            0,
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = erc20.balanceOf(collectPrice_saleRecipient);
        uint256 platformFeeRecipientAfter = erc20.balanceOf(collectPrice_platformFeeRecipient);
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * collectPrice_platformFeeBps) / MAX_BPS;
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
        uint256 platformFeeRecipientBefore = address(collectPrice_platformFeeRecipient).balance;
        dropImp.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = address(collectPrice_tokenSaleRecipient).balance;
        uint256 platformFeeRecipientAfter = address(collectPrice_platformFeeRecipient).balance;
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * collectPrice_platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_msgValue - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferERc20ToTokenIdSaleRecipient()
        public
        erc20Currency
        pricePerTokenNotZero
        saleRecipientSet
        primarySaleRecipientZeroAddress
    {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(collectPrice_tokenSaleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(collectPrice_platformFeeRecipient);
        erc20.approve(address(dropImp), collectPrice_pricePerToken);
        dropImp.collectPriceOnClaimHarness(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = erc20.balanceOf(collectPrice_tokenSaleRecipient);
        uint256 platformFeeRecipientAfter = erc20.balanceOf(collectPrice_platformFeeRecipient);
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * collectPrice_platformFeeBps) / MAX_BPS;
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
        uint256 balanceSaleRecipientBefore = address(collectPrice_saleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(collectPrice_platformFeeRecipient).balance;
        dropImp.collectPriceOnClaimHarness{ value: collectPrice_msgValue }(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = address(collectPrice_saleRecipient).balance;
        uint256 platformFeeRecipientAfter = address(collectPrice_platformFeeRecipient).balance;
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * collectPrice_platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_msgValue - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }

    function test_transferERC20ToPrimarySaleRecipient() public erc20Currency pricePerTokenNotZero {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(collectPrice_saleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(collectPrice_platformFeeRecipient);
        erc20.approve(address(dropImp), collectPrice_pricePerToken);
        dropImp.collectPriceOnClaimHarness(
            0,
            address(0),
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );

        uint256 balanceSaleRecipientAfter = erc20.balanceOf(collectPrice_saleRecipient);
        uint256 platformFeeRecipientAfter = erc20.balanceOf(collectPrice_platformFeeRecipient);
        uint256 expectedPlatformFee = (collectPrice_pricePerToken * collectPrice_platformFeeBps) / MAX_BPS;
        uint256 expectedSaleRecipientProceed = collectPrice_pricePerToken - expectedPlatformFee;

        assertEq(balanceSaleRecipientAfter - balanceSaleRecipientBefore, expectedSaleRecipientProceed);
        assertEq(platformFeeRecipientAfter - platformFeeRecipientBefore, expectedPlatformFee);
    }
}
