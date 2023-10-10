// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "lib/forge-std/src/StdCheats.sol";

contract HarnessDropERC20CollectPriceOnClaim is DropERC20 {
    bytes private emptyBytes = bytes("");

    function harness_collectPrice(
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
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");

        _setupContractURI(_contractURI);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupPrimarySaleRecipient(_saleRecipient);
    }
}

contract DropERC20Test_collectPrice is BaseTest {
    using StringsUpgradeable for uint256;

    HarnessDropERC20CollectPriceOnClaim public drop;

    address private currency;
    address private primarySaleRecipient;
    uint256 private msgValue;
    uint256 private pricePerToken;

    function setUp() public override {
        super.setUp();

        drop = new HarnessDropERC20CollectPriceOnClaim();
        drop.initializeHarness(deployer, CONTRACT_URI, saleRecipient, platformFeeBps, platformFeeRecipient);
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
        drop.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);
    }

    function test_revert_nativeCurrencyTotalPriceZero() public pricePerTokenNotZero msgValueZero currencyNativeToken {
        vm.expectRevert("quantity too low");
        drop.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 0, currency, pricePerToken);
    }

    function test_revert_nativeCurrencyValuePriceMismatch() public currencyNativeToken valuePriceMismatch {
        vm.expectRevert("Invalid msg value");
        drop.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);
    }

    function test_revert_erc20ValuePriceMismatch() public currencyNotNativeToken valuePriceMismatch {
        vm.expectRevert("Invalid msg value");
        drop.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);
    }

    function test_state_nativeCurrency()
        public
        currencyNativeToken
        pricePerTokenNotZero
        msgValueNotZero
        primarySaleRecipientNotZeroAddress
    {
        (address platformFeeRecipient, uint16 platformFeeBps) = drop.getPlatformFeeInfo();
        uint256 beforeBalancePrimarySaleRecipient = address(primarySaleRecipient).balance;
        uint256 beforeBalancePlatformFeeRecipient = address(platformFeeRecipient).balance;

        drop.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = address(primarySaleRecipient).balance;
        uint256 afterBalancePlatformFeeRecipient = address(platformFeeRecipient).balance;

        uint256 platformFeeVal = (msgValue * platformFeeBps) / MAX_BPS;
        uint256 primarySaleRecipientVal = msgValue - platformFeeVal;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
        assertEq(beforeBalancePlatformFeeRecipient + platformFeeVal, afterBalancePlatformFeeRecipient);
    }

    function test_revert_erc20_msgValueNotZero()
        public
        currencyNotNativeToken
        msgValueNotZero
        primarySaleRecipientNotZeroAddress
    {
        vm.expectRevert("!Value");
        drop.harness_collectPrice{ value: msgValue }(primarySaleRecipient, msgValue, currency, pricePerToken);
    }

    function test_state_erc20() public currencyNotNativeToken pricePerTokenNotZero primarySaleRecipientNotZeroAddress {
        (address platformFeeRecipient, uint16 platformFeeBps) = drop.getPlatformFeeInfo();

        erc20.mint(address(this), pricePerToken);
        ERC20(erc20).approve(address(drop), pricePerToken);
        uint256 beforeBalancePrimarySaleRecipient = erc20.balanceOf(primarySaleRecipient);
        uint256 beforeBalancePlatformFeeRecipient = erc20.balanceOf(platformFeeRecipient);

        drop.harness_collectPrice(primarySaleRecipient, pricePerToken, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = erc20.balanceOf(primarySaleRecipient);
        uint256 afterBalancePlatformFeeRecipient = erc20.balanceOf(platformFeeRecipient);

        uint256 platformFeeVal = (pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 primarySaleRecipientVal = 1 ether - platformFeeVal;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
        assertEq(beforeBalancePlatformFeeRecipient + platformFeeVal, afterBalancePlatformFeeRecipient);
    }

    function test_state_erc20StoredPrimarySaleRecipient()
        public
        currencyNotNativeToken
        pricePerTokenNotZero
        primarySaleRecipientZeroAddress
    {
        (address platformFeeRecipient, uint16 platformFeeBps) = drop.getPlatformFeeInfo();
        address storedPrimarySaleRecipient = drop.primarySaleRecipient();

        erc20.mint(address(this), pricePerToken);
        ERC20(erc20).approve(address(drop), pricePerToken);
        uint256 beforeBalancePrimarySaleRecipient = erc20.balanceOf(storedPrimarySaleRecipient);
        uint256 beforeBalancePlatformFeeRecipient = erc20.balanceOf(platformFeeRecipient);

        drop.harness_collectPrice(primarySaleRecipient, pricePerToken, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = erc20.balanceOf(storedPrimarySaleRecipient);
        uint256 afterBalancePlatformFeeRecipient = erc20.balanceOf(platformFeeRecipient);

        uint256 platformFeeVal = (pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 primarySaleRecipientVal = 1 ether - platformFeeVal;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
        assertEq(beforeBalancePlatformFeeRecipient + platformFeeVal, afterBalancePlatformFeeRecipient);
    }

   function test_state_nativeCurrencyStoredPrimarySaleRecipient() public currencyNativeToken pricePerTokenNotZero primarySaleRecipientZeroAddress msgValueNotZero {
        (address platformFeeRecipient, uint16 platformFeeBps) = drop.getPlatformFeeInfo();
        address storedPrimarySaleRecipient = drop.primarySaleRecipient();

        uint256 beforeBalancePrimarySaleRecipient = address(storedPrimarySaleRecipient).balance;
        uint256 beforeBalancePlatformFeeRecipient = address(platformFeeRecipient).balance;

        drop.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = address(storedPrimarySaleRecipient).balance;
        uint256 afterBalancePlatformFeeRecipient = address(platformFeeRecipient).balance;

        uint256 platformFeeVal = (msgValue * platformFeeBps) / MAX_BPS;
        uint256 primarySaleRecipientVal = msgValue - platformFeeVal;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
        assertEq(beforeBalancePlatformFeeRecipient + platformFeeVal, afterBalancePlatformFeeRecipient);
    }
}
