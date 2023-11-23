// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";

contract CreateListingTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;

    // Default listing parameters
    IDirectListings.ListingParameters internal listingParams;

    // Events to test

    /// @notice Emitted when a new listing is created.
    event NewListing(
        address indexed listingCreator,
        uint256 indexed listingId,
        address indexed assetContract,
        IDirectListings.Listing listing
    );

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
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
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

    function test_createListing_whenCallerDoesNotHaveListerRole() public {
        bytes32 role = keccak256("LISTER_ROLE");
        assertEq(Permissions(marketplace).hasRole(role, seller), false);

        vm.prank(seller);
        vm.expectRevert("!LISTER_ROLE");
        DirectListingsLogic(marketplace).createListing(listingParams);
    }

    modifier whenCallerHasListerRole() {
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        _;
    }

    function test_createListing_whenAssetDoesNotHaveAssetRole() public whenCallerHasListerRole {
        bytes32 role = keccak256("ASSET_ROLE");
        assertEq(Permissions(marketplace).hasRole(role, listingParams.assetContract), false);

        vm.prank(seller);
        vm.expectRevert("!ASSET_ROLE");
        DirectListingsLogic(marketplace).createListing(listingParams);
    }

    modifier whenAssetHasAssetRole() {
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), listingParams.assetContract);
        _;
    }

    function test_createListing_startTimeGteEndTime() public whenCallerHasListerRole whenAssetHasAssetRole {
        listingParams.startTimestamp = 200;
        listingParams.endTimestamp = 100;

        vm.prank(seller);
        vm.expectRevert("Marketplace: endTimestamp not greater than startTimestamp.");
        DirectListingsLogic(marketplace).createListing(listingParams);

        listingParams.endTimestamp = 200;

        vm.prank(seller);
        vm.expectRevert("Marketplace: endTimestamp not greater than startTimestamp.");
        DirectListingsLogic(marketplace).createListing(listingParams);
    }

    modifier whenStartTimeLtEndTime() {
        listingParams.startTimestamp = 100;
        listingParams.endTimestamp = 200;
        _;
    }

    modifier whenStartTimeLtBlockTimestamp() {
        // This warp has no effect on subsequent tests since they include a vm.warp in their own test body.
        vm.warp(listingParams.startTimestamp + 1);
        _;
    }

    function test_createListing_whenStartTimeMoreThanHourBeforeBlockTimestamp()
        public
        whenCallerHasListerRole
        whenAssetHasAssetRole
        whenStartTimeLtEndTime
        whenStartTimeLtBlockTimestamp
    {
        vm.warp(listingParams.startTimestamp + (60 minutes + 1));

        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid startTimestamp.");
        DirectListingsLogic(marketplace).createListing(listingParams);
    }

    modifier whenStartTimeWithinHourOfBlockTimestamp() {
        vm.warp(listingParams.startTimestamp + 59 minutes);
        _;
    }

    function test_createListing_whenListingParamsAreInvalid_1()
        public
        whenCallerHasListerRole
        whenAssetHasAssetRole
        whenStartTimeLtEndTime
        whenStartTimeLtBlockTimestamp
        whenStartTimeWithinHourOfBlockTimestamp
    {
        // This is one of the ways in which params are considered invalid.
        // We've written separate BTT tests for `_validateNewListing`
        listingParams.quantity = 0;

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        DirectListingsLogic(marketplace).createListing(listingParams);
    }

    modifier whenListingParamsAreValid() {
        // Approve marketplace to transfer tokens -- else listing params are considered invalid.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);
        _;
    }

    function test_createListing_whenListingParamsAreValid_1()
        public
        whenCallerHasListerRole
        whenAssetHasAssetRole
        whenStartTimeLtEndTime
        whenStartTimeLtBlockTimestamp
        whenStartTimeWithinHourOfBlockTimestamp
        whenListingParamsAreValid
    {
        uint256 expectedListingId = 0;

        assertEq(DirectListingsLogic(marketplace).totalListings(), 0);
        assertEq(DirectListingsLogic(marketplace).getListing(expectedListingId).assetContract, address(0));

        IDirectListings.Listing memory listing;

        vm.prank(seller);
        vm.expectEmit(true, true, true, false);
        emit NewListing(seller, expectedListingId, listingParams.assetContract, listing);
        DirectListingsLogic(marketplace).createListing(listingParams);

        listing = DirectListingsLogic(marketplace).getListing(expectedListingId);
        assertEq(listing.assetContract, listingParams.assetContract);
        assertEq(listing.tokenId, listingParams.tokenId);
        assertEq(listing.quantity, listingParams.quantity);
        assertEq(listing.currency, listingParams.currency);
        assertEq(listing.pricePerToken, listingParams.pricePerToken);
        assertEq(listing.endTimestamp, block.timestamp + (listingParams.endTimestamp - listingParams.startTimestamp));
        assertEq(listing.startTimestamp, block.timestamp);
        assertEq(listing.listingCreator, seller);
        assertEq(listing.reserved, true);
        assertEq(uint256(listing.status), 1); // Status.CREATED
        assertEq(uint256(listing.tokenType), 0); // TokenType.ERC721

        assertEq(DirectListingsLogic(marketplace).totalListings(), 1);
        assertEq(DirectListingsLogic(marketplace).getAllListings(0, 0).length, 1);
        assertEq(DirectListingsLogic(marketplace).getAllValidListings(0, 0).length, 1);
    }

    modifier whenStartTimeGteBlockTimestamp() {
        vm.warp(listingParams.startTimestamp - 1 minutes);
        _;
    }

    function test_createListing_whenListingParamsAreInvalid_2()
        public
        whenCallerHasListerRole
        whenAssetHasAssetRole
        whenStartTimeLtEndTime
        whenStartTimeGteBlockTimestamp
    {
        // This is one of the ways in which params are considered invalid.
        // We've written separate BTT tests for `_validateNewListing`
        listingParams.quantity = 0;

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        DirectListingsLogic(marketplace).createListing(listingParams);
    }

    function test_createListing_whenListingParamsAreValid_2()
        public
        whenCallerHasListerRole
        whenAssetHasAssetRole
        whenStartTimeLtEndTime
        whenStartTimeGteBlockTimestamp
        whenListingParamsAreValid
    {
        uint256 expectedListingId = 0;

        assertEq(DirectListingsLogic(marketplace).totalListings(), 0);
        assertEq(DirectListingsLogic(marketplace).getListing(expectedListingId).assetContract, address(0));

        IDirectListings.Listing memory listing;

        vm.prank(seller);
        vm.expectEmit(true, true, true, false);
        emit NewListing(seller, expectedListingId, listingParams.assetContract, listing);
        DirectListingsLogic(marketplace).createListing(listingParams);

        listing = DirectListingsLogic(marketplace).getListing(expectedListingId);
        assertEq(listing.assetContract, listingParams.assetContract);
        assertEq(listing.tokenId, listingParams.tokenId);
        assertEq(listing.quantity, listingParams.quantity);
        assertEq(listing.currency, listingParams.currency);
        assertEq(listing.pricePerToken, listingParams.pricePerToken);
        assertEq(listing.endTimestamp, listingParams.endTimestamp);
        assertEq(listing.startTimestamp, listingParams.startTimestamp);
        assertEq(listing.listingCreator, seller);
        assertEq(listing.reserved, true);
        assertEq(uint256(listing.status), 1); // Status.CREATED
        assertEq(uint256(listing.tokenType), 0); // TokenType.ERC721

        assertEq(DirectListingsLogic(marketplace).totalListings(), 1);
        assertEq(DirectListingsLogic(marketplace).getAllListings(0, 0).length, 1);
        assertEq(DirectListingsLogic(marketplace).getAllValidListings(0, 0).length, 0);
    }
}
