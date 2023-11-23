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

contract PayoutTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public buyer;

    // Default listing parameters
    IDirectListings.ListingParameters internal listingParams;
    uint256 internal listingId = 0;

    // Events to test

    /// @notice Emitted when a listing is updated.
    event UpdatedListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        IDirectListings.Listing listing
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
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
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

        // Mint 1 ERC721 NFT to seller
        erc721.mint(seller, listingParams.quantity);

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

    address payable[] internal mockRecipients;
    uint256[] internal mockAmounts;
    MockRoyaltyEngineV1 internal royaltyEngine;

    function _setupRoyaltyEngine() private {
        mockRecipients.push(payable(address(0x12345)));
        mockRecipients.push(payable(address(0x56789)));

        mockAmounts.push(10 ether);
        mockAmounts.push(15 ether);

        royaltyEngine = new MockRoyaltyEngineV1(mockRecipients, mockAmounts);
    }

    function _setupListingForRoyaltyTests(address erc721TokenAddress) private returns (uint256 _listingId) {
        // Sample listing parameters.
        address assetContract = erc721TokenAddress;
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 100 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = false;

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        IERC721(erc721TokenAddress).setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParameters = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        _listingId = DirectListingsLogic(marketplace).createListing(listingParameters);
    }

    function _buyFromListingForRoyaltyTests(uint256 _listingId) private returns (uint256 totalPrice) {
        IDirectListings.Listing memory listing = DirectListingsLogic(marketplace).getListing(_listingId);

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        totalPrice = pricePerToken * quantityToBuy;

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        DirectListingsLogic(marketplace).buyFromListing(_listingId, buyFor, quantityToBuy, currency, totalPrice);
    }

    function test_payout_whenZeroRoyaltyRecipients() public {
        // 1. ========= Create listing =========
        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        listingId = DirectListingsLogic(marketplace).createListing(listingParams);
        vm.stopPrank();

        // 2. ========= Buy from listing =========

        uint256 totalPrice = listingParams.pricePerToken;

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listingParams.startTimestamp);
        vm.prank(buyer);
        DirectListingsLogic(marketplace).buyFromListing(
            listingId,
            buyer,
            listingParams.quantity,
            listingParams.currency,
            totalPrice
        );

        // 3. ======== Check balances after royalty payments ========

        uint256 platformFees = (totalPrice * platformFeeBps) / 10_000;

        {
            // Platform fee recipient receives correct amount
            assertBalERC20Eq(address(erc20), platformFeeRecipient, platformFees);

            // Seller gets total price minus royalty amounts
            assertBalERC20Eq(address(erc20), seller, totalPrice - platformFees);
        }
    }

    modifier whenNonZeroRoyaltyRecipients() {
        _setupRoyaltyEngine();

        // Add RoyaltyEngine to marketplace
        vm.prank(marketplaceDeployer);
        RoyaltyPaymentsLogic(marketplace).setRoyaltyEngine(address(royaltyEngine));

        _;
    }

    function test_payout_whenInsufficientFundsToPayRoyaltyAfterPlatformFeePayout() public whenNonZeroRoyaltyRecipients {
        vm.prank(marketplaceDeployer);
        PlatformFee(marketplace).setPlatformFeeInfo(platformFeeRecipient, 9999); // 99.99% fees

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        erc721.mint(seller, 1);
        listingId = _setupListingForRoyaltyTests(address(erc721));

        IDirectListings.Listing memory listing = DirectListingsLogic(marketplace).getListing(listingId);

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("fees exceed the price");
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
    }

    function test_payout_whenSufficientFundsToPayRoyaltyAfterPlatformFeePayout() public whenNonZeroRoyaltyRecipients {
        assertEq(RoyaltyPaymentsLogic(marketplace).getRoyaltyEngineAddress(), address(royaltyEngine));

        // 1. ========= Create listing =========

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        erc721.mint(seller, 1);
        listingId = _setupListingForRoyaltyTests(address(erc721));

        // 2. ========= Buy from listing =========

        uint256 totalPrice = _buyFromListingForRoyaltyTests(listingId);

        // 3. ======== Check balances after royalty payments ========

        uint256 platformFees = (totalPrice * platformFeeBps) / 10_000;

        {
            // Royalty recipients receive correct amounts
            assertBalERC20Eq(address(erc20), mockRecipients[0], mockAmounts[0]);
            assertBalERC20Eq(address(erc20), mockRecipients[1], mockAmounts[1]);

            // Platform fee recipient receives correct amount
            assertBalERC20Eq(address(erc20), platformFeeRecipient, platformFees);

            // Seller gets total price minus royalty amounts
            assertBalERC20Eq(address(erc20), seller, totalPrice - mockAmounts[0] - mockAmounts[1] - platformFees);
        }
    }
}
