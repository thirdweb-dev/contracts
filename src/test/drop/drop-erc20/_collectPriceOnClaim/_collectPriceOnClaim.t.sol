// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC20CollectPriceOnClaim is DropERC20 {
    function harness_collectPrice(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) public payable {
        _collectPriceOnClaim(_primarySaleRecipient, _quantityToClaim, _currency, _pricePerToken);
    }
}

contract DropERC20Test_collectPrice is BaseTest {
    address public dropImp;
    HarnessDropERC20CollectPriceOnClaim public proxy;

    address private currency;
    address private primarySaleRecipient;
    uint256 private msgValue;
    uint256 private pricePerToken;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC20.initialize,
            (deployer, NAME, SYMBOL, CONTRACT_URI, forwarders(), saleRecipient, platformFeeRecipient, platformFeeBps)
        );

        dropImp = address(new HarnessDropERC20CollectPriceOnClaim());
        proxy = HarnessDropERC20CollectPriceOnClaim(address(new TWProxy(dropImp, initializeData)));
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
        proxy.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);
    }

    function test_revert_nativeCurrencyTotalPriceZero() public pricePerTokenNotZero msgValueZero currencyNativeToken {
        vm.expectRevert("quantity too low");
        proxy.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 0, currency, pricePerToken);
    }

    function test_revert_nativeCurrencyValuePriceMismatch() public currencyNativeToken valuePriceMismatch {
        vm.expectRevert("Invalid msg value");
        proxy.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);
    }

    function test_revert_erc20ValuePriceMismatch() public currencyNotNativeToken valuePriceMismatch {
        vm.expectRevert("Invalid msg value");
        proxy.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);
    }

    function test_state_nativeCurrency()
        public
        currencyNativeToken
        pricePerTokenNotZero
        msgValueNotZero
        primarySaleRecipientNotZeroAddress
    {
        (address platformFeeRecipient, uint16 platformFeeBps) = proxy.getPlatformFeeInfo();
        uint256 beforeBalancePrimarySaleRecipient = address(primarySaleRecipient).balance;
        uint256 beforeBalancePlatformFeeRecipient = address(platformFeeRecipient).balance;

        proxy.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);

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
        proxy.harness_collectPrice{ value: msgValue }(primarySaleRecipient, msgValue, currency, pricePerToken);
    }

    function test_state_erc20() public currencyNotNativeToken pricePerTokenNotZero primarySaleRecipientNotZeroAddress {
        (address platformFeeRecipient, uint16 platformFeeBps) = proxy.getPlatformFeeInfo();

        erc20.mint(address(this), pricePerToken);
        ERC20(erc20).approve(address(proxy), pricePerToken);
        uint256 beforeBalancePrimarySaleRecipient = erc20.balanceOf(primarySaleRecipient);
        uint256 beforeBalancePlatformFeeRecipient = erc20.balanceOf(platformFeeRecipient);

        proxy.harness_collectPrice(primarySaleRecipient, pricePerToken, currency, pricePerToken);

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
        (address platformFeeRecipient, uint16 platformFeeBps) = proxy.getPlatformFeeInfo();
        address storedPrimarySaleRecipient = proxy.primarySaleRecipient();

        erc20.mint(address(this), pricePerToken);
        ERC20(erc20).approve(address(proxy), pricePerToken);
        uint256 beforeBalancePrimarySaleRecipient = erc20.balanceOf(storedPrimarySaleRecipient);
        uint256 beforeBalancePlatformFeeRecipient = erc20.balanceOf(platformFeeRecipient);

        proxy.harness_collectPrice(primarySaleRecipient, pricePerToken, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = erc20.balanceOf(storedPrimarySaleRecipient);
        uint256 afterBalancePlatformFeeRecipient = erc20.balanceOf(platformFeeRecipient);

        uint256 platformFeeVal = (pricePerToken * platformFeeBps) / MAX_BPS;
        uint256 primarySaleRecipientVal = 1 ether - platformFeeVal;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
        assertEq(beforeBalancePlatformFeeRecipient + platformFeeVal, afterBalancePlatformFeeRecipient);
    }

    function test_state_nativeCurrencyStoredPrimarySaleRecipient()
        public
        currencyNativeToken
        pricePerTokenNotZero
        primarySaleRecipientZeroAddress
        msgValueNotZero
    {
        (address platformFeeRecipient, uint16 platformFeeBps) = proxy.getPlatformFeeInfo();
        address storedPrimarySaleRecipient = proxy.primarySaleRecipient();

        uint256 beforeBalancePrimarySaleRecipient = address(storedPrimarySaleRecipient).balance;
        uint256 beforeBalancePlatformFeeRecipient = address(platformFeeRecipient).balance;

        proxy.harness_collectPrice{ value: msgValue }(primarySaleRecipient, 1 ether, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = address(storedPrimarySaleRecipient).balance;
        uint256 afterBalancePlatformFeeRecipient = address(platformFeeRecipient).balance;

        uint256 platformFeeVal = (msgValue * platformFeeBps) / MAX_BPS;
        uint256 primarySaleRecipientVal = msgValue - platformFeeVal;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
        assertEq(beforeBalancePlatformFeeRecipient + platformFeeVal, afterBalancePlatformFeeRecipient);
    }
}
