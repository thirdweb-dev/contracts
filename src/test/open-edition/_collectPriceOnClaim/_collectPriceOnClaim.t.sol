// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { OpenEditionERC721 } from "contracts/prebuilts/open-edition/OpenEditionERC721.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract OpenEditionERC721Harness is OpenEditionERC721 {
    function collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) external payable {
        _collectPriceOnClaim(_primarySaleRecipient, _quantityToClaim, _currency, _pricePerToken);
    }
}

contract OpenEditionERC721Test_collectPrice is BaseTest {
    OpenEditionERC721Harness public openEdition;

    address private openEditionImpl;

    address private currency;
    address private primarySaleRecipient;
    uint256 private msgValue;
    uint256 private pricePerToken;
    uint256 private qty = 1;

    function setUp() public override {
        super.setUp();
        openEditionImpl = address(new OpenEditionERC721Harness());
        vm.prank(deployer);
        openEdition = OpenEditionERC721Harness(
            address(
                new TWProxy(
                    openEditionImpl,
                    abi.encodeCall(
                        OpenEditionERC721.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps
                        )
                    )
                )
            )
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc
    //////////////////////////////////////////////////////////////*/

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
        openEdition.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    function test_revert_nativeCurrencyValuePriceMismatch() public currencyNativeToken valuePriceMismatch {
        vm.expectRevert(bytes("!V"));
        openEdition.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    function test_revert_erc20ValuePriceMismatch() public currencyNotNativeToken valuePriceMismatch {
        vm.expectRevert(bytes("!V"));
        openEdition.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    function test_state_nativeCurrency()
        public
        currencyNativeToken
        pricePerTokenNotZero
        msgValueNotZero
        primarySaleRecipientNotZeroAddress
    {
        uint256 beforeBalancePrimarySaleRecipient = address(primarySaleRecipient).balance;

        openEdition.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = address(primarySaleRecipient).balance;

        uint256 primarySaleRecipientVal = msgValue;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
    }

    function test_revert_erc20_msgValueNotZero()
        public
        currencyNotNativeToken
        msgValueNotZero
        primarySaleRecipientNotZeroAddress
    {
        vm.expectRevert("!Value");
        openEdition.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);
    }

    function test_state_erc20() public currencyNotNativeToken pricePerTokenNotZero primarySaleRecipientNotZeroAddress {
        erc20.mint(address(this), pricePerToken);
        ERC20(erc20).approve(address(openEdition), pricePerToken);
        uint256 beforeBalancePrimarySaleRecipient = erc20.balanceOf(primarySaleRecipient);

        openEdition.collectPriceOnClaim(primarySaleRecipient, qty, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = erc20.balanceOf(primarySaleRecipient);

        uint256 primarySaleRecipientVal = 1 ether;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
    }

    function test_state_erc20StoredPrimarySaleRecipient()
        public
        currencyNotNativeToken
        pricePerTokenNotZero
        primarySaleRecipientZeroAddress
    {
        address storedPrimarySaleRecipient = openEdition.primarySaleRecipient();

        erc20.mint(address(this), pricePerToken);
        ERC20(erc20).approve(address(openEdition), pricePerToken);
        uint256 beforeBalancePrimarySaleRecipient = erc20.balanceOf(storedPrimarySaleRecipient);

        openEdition.collectPriceOnClaim(primarySaleRecipient, qty, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = erc20.balanceOf(storedPrimarySaleRecipient);

        uint256 primarySaleRecipientVal = 1 ether;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
    }

    function test_state_nativeCurrencyStoredPrimarySaleRecipient()
        public
        currencyNativeToken
        pricePerTokenNotZero
        primarySaleRecipientZeroAddress
        msgValueNotZero
    {
        address storedPrimarySaleRecipient = openEdition.primarySaleRecipient();

        uint256 beforeBalancePrimarySaleRecipient = address(storedPrimarySaleRecipient).balance;

        openEdition.collectPriceOnClaim{ value: msgValue }(primarySaleRecipient, qty, currency, pricePerToken);

        uint256 afterBalancePrimarySaleRecipient = address(storedPrimarySaleRecipient).balance;

        uint256 primarySaleRecipientVal = msgValue;

        assertEq(beforeBalancePrimarySaleRecipient + primarySaleRecipientVal, afterBalancePrimarySaleRecipient);
    }
}
