// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract HarnessDropERC721 is DropERC721 {
    function collectionPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) public payable {
        _collectPriceOnClaim(_primarySaleRecipient, _quantityToClaim, _currency, _pricePerToken);
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

contract DropERC721Test_collectPrice is BaseTest {
    using StringsUpgradeable for uint256;

    HarnessDropERC721 public dropImp;

    address private collectPrice_saleRecipient = address(0x010);
    address private collectPrice_royaltyRecipient = address(0x011);
    uint128 private collectPrice_royaltyBps = 1000;
    uint128 private collectPrice_platformFeeBps = 1000;
    address private collectPrice_platformFeeRecipient = address(0x012);
    uint256 private collectPrice_quantityToClaim = 1;
    uint256 private collectPrice_pricePerToken;
    address private collectPrice_currency;
    uint256 private collectPrice_msgValue;

    function setUp() public override {
        super.setUp();

        dropImp = new HarnessDropERC721();
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

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    function test_revert_msgValueNotZero() public nativeCurrency msgValueNotZero pricePerTokenZero {
        vm.expectRevert();
        dropImp.collectionPriceOnClaim{ value: collectPrice_msgValue }(
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_revert_priceValueMismatchNativeCurrency() public nativeCurrency pricePerTokenNotZero {
        vm.expectRevert();
        dropImp.collectionPriceOnClaim{ value: collectPrice_msgValue }(
            collectPrice_saleRecipient,
            collectPrice_quantityToClaim,
            collectPrice_currency,
            collectPrice_pricePerToken
        );
    }

    function test_transferNativeCurrency() public nativeCurrency pricePerTokenNotZero msgValueNotZero {
        uint256 balanceSaleRecipientBefore = address(collectPrice_saleRecipient).balance;
        uint256 platformFeeRecipientBefore = address(collectPrice_platformFeeRecipient).balance;
        dropImp.collectionPriceOnClaim{ value: collectPrice_msgValue }(
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

    function test_transferERC20() public erc20Currency pricePerTokenNotZero {
        uint256 balanceSaleRecipientBefore = erc20.balanceOf(collectPrice_saleRecipient);
        uint256 platformFeeRecipientBefore = erc20.balanceOf(collectPrice_platformFeeRecipient);
        erc20.approve(address(dropImp), collectPrice_pricePerToken);
        dropImp.collectionPriceOnClaim(
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
}
