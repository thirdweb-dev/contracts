// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { RoyaltyPaymentsLogic } from "contracts/extension/plugin/RoyaltyPayments.sol";
import { PlatformFee } from "contracts/extension/PlatformFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";
import { MockRoyaltyEngineV1 } from "../../../mocks/MockRoyaltyEngineV1.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract ReentrantRecipient is ERC1155Holder {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bytes4) {
        DirectListingsLogic(msg.sender).buyFromListing(0, address(this), 1, address(0), 0);
        return super.onERC1155Received(operator, from, id, value, data);
    }
}

contract BuyFromListingTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public buyer;

    // Default listing parameters
    IDirectListings.ListingParameters internal listingParams;

    uint256 internal listingId = type(uint256).max;
    uint256 internal listingId_native_noSpecialPrice = 0;
    uint256 internal listingId_native_specialPrice = 1;
    uint256 internal listingId_erc20_noSpecialPrice = 2;
    uint256 internal listingId_erc20_specialPrice = 3;

    // Events to test

    /// @notice Emitted when NFTs are bought from a listing.
    event NewSale(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        uint256 tokenId,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    function setUp() public override {
        super.setUp();

        marketplaceDeployer = getActor(1);
        seller = getActor(2);
        buyer = getActor(3);

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address impl = address(
            new MarketplaceV3(MarketplaceV3.MarketplaceConstructorParams(extensions, address(0), address(weth)))
        );

        vm.prank(marketplaceDeployer);
        marketplace = address(
            new TWProxy(
                impl,
                abi.encodeCall(
                    MarketplaceV3.initialize,
                    (marketplaceDeployer, "", new address[](0), platformFeeRecipient, uint16(platformFeeBps))
                )
            )
        );

        // Setup listing params
        address assetContract = address(erc1155);
        uint256 tokenId = 0;
        uint256 quantity = 10;
        address currency = NATIVE_TOKEN;
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100 minutes;
        uint128 endTimestamp = 200 minutes;
        bool reserved = false;

        listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        // Mint currency to buyer
        vm.deal(buyer, 100 ether);
        erc20.mint(buyer, 100 ether);

        // Mint an ERC721 NFTs to seller
        erc1155.mint(seller, 0, 100);
        vm.prank(seller);
        erc1155.setApprovalForAll(marketplace, true);

        // Create 4 listings
        vm.startPrank(seller);

        // 1. Native token, no special price
        listingParams.currency = NATIVE_TOKEN;
        listingId_native_noSpecialPrice = DirectListingsLogic(marketplace).createListing(listingParams);

        // 2. Native token, special price
        listingParams.currency = address(erc20);
        listingId_native_specialPrice = DirectListingsLogic(marketplace).createListing(listingParams);
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId_native_specialPrice,
            NATIVE_TOKEN,
            2 ether
        );

        // 3. ERC20 token, no special price
        listingParams.currency = address(erc20);
        listingId_erc20_noSpecialPrice = DirectListingsLogic(marketplace).createListing(listingParams);

        // 4. ERC20 token, special price
        listingParams.currency = NATIVE_TOKEN;
        listingId_erc20_specialPrice = DirectListingsLogic(marketplace).createListing(listingParams);
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId_erc20_specialPrice,
            address(erc20),
            2 ether
        );

        vm.stopPrank();

        vm.label(impl, "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](1);

        // Deploy `DirectListings`
        address directListings = address(new DirectListingsLogic(address(weth)));
        vm.label(directListings, "DirectListings_Extension");

        // Extension: DirectListingsLogic
        Extension memory extension_directListings;
        extension_directListings.metadata = ExtensionMetadata({
            name: "DirectListingsLogic",
            metadataURI: "ipfs://DirectListings",
            implementation: directListings
        });

        extension_directListings.functions = new ExtensionFunction[](13);
        extension_directListings.functions[0] = ExtensionFunction(
            DirectListingsLogic.totalListings.selector,
            "totalListings()"
        );
        extension_directListings.functions[1] = ExtensionFunction(
            DirectListingsLogic.isBuyerApprovedForListing.selector,
            "isBuyerApprovedForListing(uint256,address)"
        );
        extension_directListings.functions[2] = ExtensionFunction(
            DirectListingsLogic.isCurrencyApprovedForListing.selector,
            "isCurrencyApprovedForListing(uint256,address)"
        );
        extension_directListings.functions[3] = ExtensionFunction(
            DirectListingsLogic.currencyPriceForListing.selector,
            "currencyPriceForListing(uint256,address)"
        );
        extension_directListings.functions[4] = ExtensionFunction(
            DirectListingsLogic.createListing.selector,
            "createListing((address,uint256,uint256,address,uint256,uint128,uint128,bool))"
        );
        extension_directListings.functions[5] = ExtensionFunction(
            DirectListingsLogic.updateListing.selector,
            "updateListing(uint256,(address,uint256,uint256,address,uint256,uint128,uint128,bool))"
        );
        extension_directListings.functions[6] = ExtensionFunction(
            DirectListingsLogic.cancelListing.selector,
            "cancelListing(uint256)"
        );
        extension_directListings.functions[7] = ExtensionFunction(
            DirectListingsLogic.approveBuyerForListing.selector,
            "approveBuyerForListing(uint256,address,bool)"
        );
        extension_directListings.functions[8] = ExtensionFunction(
            DirectListingsLogic.approveCurrencyForListing.selector,
            "approveCurrencyForListing(uint256,address,uint256)"
        );
        extension_directListings.functions[9] = ExtensionFunction(
            DirectListingsLogic.buyFromListing.selector,
            "buyFromListing(uint256,address,uint256,address,uint256)"
        );
        extension_directListings.functions[10] = ExtensionFunction(
            DirectListingsLogic.getAllListings.selector,
            "getAllListings(uint256,uint256)"
        );
        extension_directListings.functions[11] = ExtensionFunction(
            DirectListingsLogic.getAllValidListings.selector,
            "getAllValidListings(uint256,uint256)"
        );
        extension_directListings.functions[12] = ExtensionFunction(
            DirectListingsLogic.getListing.selector,
            "getListing(uint256)"
        );

        extensions[0] = extension_directListings;
    }

    modifier whenListingCurrencyIsNativeToken() {
        listingId = listingId_native_noSpecialPrice;
        listingParams.currency = NATIVE_TOKEN;
        _;
    }

    modifier whenListingHasSpecialPriceNativeToken() {
        listingId = listingId_native_specialPrice;
        _;
    }

    modifier whenListingCurrencyIsERC20Token() {
        listingId = listingId_erc20_noSpecialPrice;
        _;
    }

    modifier whenListingHasSpecialPriceERC20Token() {
        listingId = listingId_erc20_specialPrice;
        _;
    }

    //////////// ASSUME NATIVE_TOKEN && SPECIAL_PRICE ////////////

    function test_buyFromListing_whenCallIsReentrant() public whenListingHasSpecialPriceNativeToken {
        vm.warp(listingParams.startTimestamp);
        address reentrantRecipient = address(new ReentrantRecipient());

        vm.prank(buyer);
        vm.expectRevert();
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(
            listingId,
            reentrantRecipient,
            1,
            NATIVE_TOKEN,
            2 ether
        );
    }

    modifier whenCallIsNotReentrant() {
        _;
    }

    function test_buyFromListing_whenListingDoesNotExist()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
    {
        vm.warp(listingParams.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Marketplace: invalid listing.");
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(100, buyer, 1, NATIVE_TOKEN, 2 ether);
    }

    modifier whenListingExists() {
        _;
    }

    function test_buyFromListing_whenBuyerIsNotApprovedForListing()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
    {
        listingParams.reserved = true;
        listingParams.currency = address(erc20);

        vm.prank(seller);
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);

        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("buyer not approved");
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(listingId, buyer, 1, NATIVE_TOKEN, 2 ether);
    }

    modifier whenBuyerIsApprovedForListing(address _currency) {
        listingParams.reserved = true;
        listingParams.currency = _currency;

        vm.prank(seller);
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);

        vm.prank(seller);
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);
        _;
    }

    function test_buyFromListing_whenQuantityToBuyIsInvalid()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
    {
        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("Buying invalid quantity");
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(listingId, buyer, 0, NATIVE_TOKEN, 2 ether);
    }

    modifier whenQuantityToBuyIsValid() {
        _;
    }

    function test_buyFromListing_whenListingIsInactive()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
    {
        vm.prank(buyer);
        vm.expectRevert("not within sale window.");
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(listingId, buyer, 1, NATIVE_TOKEN, 2 ether);
    }

    modifier whenListingIsActive() {
        _;
    }

    function test_buyFromListing_whenListedAssetNotOwnedOrApprovedToTransfer()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
    {
        vm.prank(seller);
        erc1155.setApprovalForAll(marketplace, false);

        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(listingId, buyer, 1, NATIVE_TOKEN, 2 ether);
    }

    modifier whenListedAssetOwnedAndApproved() {
        _;
    }

    function test_buyFromListing_whenExpectedPriceNotActualPrice()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
    {
        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("Unexpected total price");
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(listingId, buyer, 1, NATIVE_TOKEN, 1 ether);
    }

    modifier whenExpectedPriceIsActualPrice() {
        _;
    }

    function test_buyFromListing_whenMsgValueNotEqTotalPrice()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
        whenExpectedPriceIsActualPrice
    {
        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("Marketplace: msg.value must exactly be the total price.");
        DirectListingsLogic(marketplace).buyFromListing{ value: 1 ether }(listingId, buyer, 1, NATIVE_TOKEN, 2 ether);
    }

    modifier whenMsgValueEqTotalPrice() {
        _;
    }

    function test_buyFromListing_whenAllRemainingQtyIsBought_nativeToken()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
        whenExpectedPriceIsActualPrice
        whenMsgValueEqTotalPrice
    {
        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 100);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), 0);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.CREATED)
        );

        vm.warp(listingParams.startTimestamp);
        vm.prank(buyer);
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether * listingParams.quantity }(
            listingId,
            buyer,
            listingParams.quantity,
            NATIVE_TOKEN,
            2 ether * listingParams.quantity
        );

        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 100 - listingParams.quantity);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), listingParams.quantity);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.COMPLETED)
        );
    }

    function test_buyFromListing_whenSomeRemainingQtyIsBought_nativeToken()
        public
        whenListingHasSpecialPriceNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
        whenExpectedPriceIsActualPrice
        whenMsgValueEqTotalPrice
    {
        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 100);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), 0);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.CREATED)
        );

        vm.warp(listingParams.startTimestamp);
        vm.prank(buyer);
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether }(listingId, buyer, 1, NATIVE_TOKEN, 2 ether);

        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 99);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), 1);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.CREATED)
        );
    }

    //////////// ASSUME NATIVE_TOKEN && NO_SPECIAL_PRICE ////////////

    function test_buyFromListing_whenCurrencyToUseNotListedCurrency()
        public
        whenListingCurrencyIsNativeToken
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(NATIVE_TOKEN)
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
    {
        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("Paying in invalid currency.");
        DirectListingsLogic(marketplace).buyFromListing{ value: 2 ether * listingParams.quantity }(
            listingId,
            buyer,
            listingParams.quantity,
            address(erc20),
            2 ether * listingParams.quantity
        );
    }

    //////////// ASSUME ERC20 && NO_SPECIAL_PRICE ////////////

    function test_buyFromListing_whenInsufficientTokenBalanceOrAllowance()
        public
        whenListingCurrencyIsERC20Token
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
        whenExpectedPriceIsActualPrice
    {
        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("!BAL20");
        DirectListingsLogic(marketplace).buyFromListing(
            listingId,
            buyer,
            listingParams.quantity,
            address(erc20),
            1 ether * listingParams.quantity
        );
    }

    modifier whenSufficientTokenBalanceOrAllowance() {
        vm.prank(buyer);
        erc20.approve(marketplace, 100 ether);
        _;
    }

    function test_buyFromListing_whenMsgValueNotZero()
        public
        whenListingCurrencyIsERC20Token
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
        whenExpectedPriceIsActualPrice
        whenSufficientTokenBalanceOrAllowance
    {
        vm.warp(listingParams.startTimestamp);

        vm.prank(buyer);
        vm.expectRevert("Marketplace: invalid native tokens sent.");
        DirectListingsLogic(marketplace).buyFromListing{ value: 1 ether }(
            listingId,
            buyer,
            listingParams.quantity,
            address(erc20),
            1 ether * listingParams.quantity
        );
    }

    modifier whenMsgValueIsZero() {
        _;
    }

    function test_buyFromListing_whenAllRemainingQtyIsBought_erc20()
        public
        whenListingCurrencyIsERC20Token
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
        whenExpectedPriceIsActualPrice
        whenSufficientTokenBalanceOrAllowance
        whenMsgValueIsZero
    {
        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 100);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), 0);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.CREATED)
        );

        vm.warp(listingParams.startTimestamp);
        vm.prank(buyer);
        DirectListingsLogic(marketplace).buyFromListing(
            listingId,
            buyer,
            listingParams.quantity,
            address(erc20),
            1 ether * listingParams.quantity
        );

        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 100 - listingParams.quantity);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), listingParams.quantity);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.COMPLETED)
        );
    }

    function test_buyFromListing_whenSomeRemainingQtyIsBought_erc20()
        public
        whenListingCurrencyIsERC20Token
        whenCallIsNotReentrant
        whenListingExists
        whenBuyerIsApprovedForListing(address(erc20))
        whenQuantityToBuyIsValid
        whenListingIsActive
        whenListedAssetOwnedAndApproved
        whenExpectedPriceIsActualPrice
        whenSufficientTokenBalanceOrAllowance
        whenMsgValueIsZero
    {
        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 100);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), 0);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.CREATED)
        );

        vm.warp(listingParams.startTimestamp);
        vm.prank(buyer);
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyer, 1, address(erc20), 1 ether);

        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), 99);
        assertEq(erc1155.balanceOf(buyer, listingParams.tokenId), 1);
        assertEq(
            uint8(DirectListingsLogic(marketplace).getListing(listingId).status),
            uint8(IDirectListings.Status.CREATED)
        );
    }
}
