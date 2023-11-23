// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";

contract ApproveCurrencyForListingTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;

    // Default listing parameters
    IDirectListings.ListingParameters internal listingParams;
    uint256 internal listingId = 0;

    // Events to test

    /// @notice Emitted when a currency is approved as a form of payment for the listing.
    event CurrencyApprovedForListing(uint256 indexed listingId, address indexed currency, uint256 pricePerToken);

    function setUp() public override {
        super.setUp();

        marketplaceDeployer = getActor(1);
        seller = getActor(2);

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
                    (marketplaceDeployer, "", new address[](0), marketplaceDeployer, 0)
                )
            )
        );

        // Setup roles
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(0));
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), address(0));

        vm.stopPrank();

        // Setup listing params
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100 minutes;
        uint128 endTimestamp = 200 minutes;
        bool reserved = true;

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

    function test_approveCurrencyForListing_listingDoesntExist() public {
        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid listing.");
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, address(weth), 1 ether);
    }

    modifier whenListingExists() {
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        vm.stopPrank();

        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        listingId = DirectListingsLogic(marketplace).createListing(listingParams);
        erc721.setApprovalForAll(marketplace, false);
        vm.stopPrank();

        vm.prank(marketplaceDeployer);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(erc721));
        _;
    }

    function test_approveCurrencyForListing_whenCallerNotListingCreator() public whenListingExists {
        vm.prank(address(0x4353));
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, address(weth), 1 ether);
    }

    modifier whenCallerIsListingCreator() {
        _;
    }

    function test_approveCurrencyForListing_whenApprovingDifferentPriceForListedCurrency()
        public
        whenListingExists
        whenCallerIsListingCreator
    {
        vm.prank(seller);
        vm.expectRevert("Marketplace: approving listing currency with different price.");
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId,
            listingParams.currency,
            listingParams.pricePerToken + 1
        );
    }

    function test_approveCurrencyForListing_whenPriceToApproveIsAlreadyApproved()
        public
        whenListingExists
        whenCallerIsListingCreator
    {
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, address(weth), 1 ether);

        vm.prank(seller);
        vm.expectRevert("Marketplace: price unchanged.");
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, address(weth), 1 ether);
    }

    function test_approveCurrencyForListing_whenApprovedPriceForCurrencyIsDifferentThanIncumbent()
        public
        whenListingExists
        whenCallerIsListingCreator
    {
        vm.expectRevert("Currency not approved for listing");
        DirectListingsLogic(marketplace).currencyPriceForListing(listingId, address(weth));

        vm.prank(seller);
        vm.expectEmit(true, true, true, true);
        emit CurrencyApprovedForListing(listingId, address(weth), 1 ether);
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, address(weth), 1 ether);

        assertEq(DirectListingsLogic(marketplace).currencyPriceForListing(listingId, address(weth)), 1 ether);
    }
}
