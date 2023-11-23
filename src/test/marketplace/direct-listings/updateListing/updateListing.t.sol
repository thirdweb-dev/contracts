// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";

contract UpdateListingTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;

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

    function test_updateListing_whenListingDoesNotExist() public {
        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid listing.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
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

    function test_updateListing_whenAssetDoesntHaveAssetRole() public whenListingExists {
        vm.prank(seller);
        vm.expectRevert("!ASSET_ROLE");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenAssetHasAssetRole() {
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        _;
    }

    function test_updateListing_whenCallerIsNotListingCreator() public whenListingExists whenAssetHasAssetRole {
        vm.prank(address(0x4567));
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenCallerIsListingCreator() {
        _;
    }

    function test_updateListing_whenListingHasExpired()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
    {
        vm.warp(listingParams.endTimestamp + 1);

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing expired.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenListingNotExpired() {
        vm.warp(0);
        _;
    }

    function test_updateListing_whenUpdatedAssetIsDifferent()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
    {
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));
        listingParams.assetContract = address(erc1155);

        vm.prank(seller);
        vm.expectRevert("Marketplace: cannot update what token is listed.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);

        listingParams.assetContract = address(erc721);
        listingParams.tokenId = 10;

        vm.prank(seller);
        vm.expectRevert("Marketplace: cannot update what token is listed.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenUpdatedAssetIsSame() {
        _;
    }

    function test_updateListing_whenUpdatedStartTimeGteEndTime()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
    {
        listingParams.startTimestamp = 200;
        listingParams.endTimestamp = 100;

        vm.prank(seller);
        vm.expectRevert("Marketplace: endTimestamp not greater than startTimestamp.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenUpdatedStartTimeLtUpdatedEndTime() {
        _;
    }

    function test_updateListing_whenUpdateMakesActiveListingInactive()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
    {
        vm.warp(listingParams.startTimestamp + 1);

        listingParams.startTimestamp += 50;

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing already active.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenUpdateDoesntMakeActiveListingInactive() {
        _;
    }

    modifier whenUpdatedStartIsDiffAndInPast() {
        vm.warp(listingParams.startTimestamp - 1 minutes);
        listingParams.startTimestamp -= 2 minutes;
        _;
    }

    function test_updateListing_whenUpdatedStartIsMoreThanHourInPast()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
        whenUpdateDoesntMakeActiveListingInactive
        whenUpdatedStartIsDiffAndInPast
    {
        listingParams.startTimestamp = 30 minutes;

        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid startTimestamp.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenUpdatedStartIsWithinPastHour() {
        listingParams.startTimestamp = 90 minutes;
        _;
    }

    function test_updateListing_whenUpdatedPriceIsDifferentFromApprovedPrice_1()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
        whenUpdateDoesntMakeActiveListingInactive
        whenUpdatedStartIsDiffAndInPast
        whenUpdatedStartIsWithinPastHour
    {
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, address(weth), 2 ether);

        listingParams.currency = address(weth);

        vm.prank(seller);
        vm.expectRevert("Marketplace: price different from approved price");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenUpdatedPriceIsSameAsApprovedPrice() {
        _;
    }

    function test_updateListing_whenListingParamsAreInvalid_1()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
        whenUpdateDoesntMakeActiveListingInactive
        whenUpdatedStartIsDiffAndInPast
        whenUpdatedStartIsWithinPastHour
        whenUpdatedPriceIsSameAsApprovedPrice
    {
        // This is one of the ways in which params can be invalid.
        // Separate tests for `_validateNewListingParams`
        listingParams.quantity = 0;

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    modifier whenListingParamsAreValid() {
        _;
    }

    function test_updateListing_whenListingParamsAreValid_1()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
        whenUpdateDoesntMakeActiveListingInactive
        whenUpdatedStartIsDiffAndInPast
        whenUpdatedStartIsWithinPastHour
        whenUpdatedPriceIsSameAsApprovedPrice
        whenListingParamsAreValid
    {
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        IDirectListings.Listing memory listing;

        vm.prank(seller);
        vm.expectEmit(true, true, true, false);
        emit UpdatedListing(seller, listingId, listingParams.assetContract, listing);
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);

        IDirectListings.Listing memory updatedListing = DirectListingsLogic(marketplace).getListing(listingId);

        assertEq(updatedListing.assetContract, listingParams.assetContract);
        assertEq(updatedListing.tokenId, listingParams.tokenId);
        assertEq(updatedListing.quantity, listingParams.quantity);
        assertEq(updatedListing.currency, listingParams.currency);
        assertEq(updatedListing.pricePerToken, listingParams.pricePerToken);
        assertEq(updatedListing.endTimestamp, listingParams.endTimestamp);
        assertEq(updatedListing.startTimestamp, block.timestamp);
        assertEq(updatedListing.listingCreator, seller);
        assertEq(updatedListing.reserved, true);
        assertEq(uint256(updatedListing.status), 1); // Status.CREATED
        assertEq(uint256(updatedListing.tokenType), 0); // TokenType.ERC721
    }

    modifier whenUpdatedStartIsSameAsCurrentStart() {
        _;
    }

    function test_updateListing_whenUpdatedPriceIsDifferentFromApprovedPrice_2()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
        whenUpdateDoesntMakeActiveListingInactive
        whenUpdatedStartIsSameAsCurrentStart
    {
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, address(weth), 2 ether);

        listingParams.currency = address(weth);

        vm.prank(seller);
        vm.expectRevert("Marketplace: price different from approved price");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    function test_updateListing_whenListingParamsAreInvalid_2()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
        whenUpdateDoesntMakeActiveListingInactive
        whenUpdatedStartIsSameAsCurrentStart
        whenUpdatedPriceIsSameAsApprovedPrice
    {
        // This is one of the ways in which params can be invalid.
        // Separate tests for `_validateNewListingParams`
        listingParams.quantity = 0;

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    function test_updateListing_whenListingParamsAreValid_2()
        public
        whenListingExists
        whenAssetHasAssetRole
        whenCallerIsListingCreator
        whenListingNotExpired
        whenUpdatedAssetIsSame
        whenUpdatedStartTimeLtUpdatedEndTime
        whenUpdateDoesntMakeActiveListingInactive
        whenUpdatedStartIsSameAsCurrentStart
        whenUpdatedPriceIsSameAsApprovedPrice
        whenListingParamsAreValid
    {
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        IDirectListings.Listing memory listing;

        vm.prank(seller);
        vm.expectEmit(true, true, true, false);
        emit UpdatedListing(seller, listingId, listingParams.assetContract, listing);
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);

        IDirectListings.Listing memory updatedListing = DirectListingsLogic(marketplace).getListing(listingId);

        assertEq(updatedListing.assetContract, listingParams.assetContract);
        assertEq(updatedListing.tokenId, listingParams.tokenId);
        assertEq(updatedListing.quantity, listingParams.quantity);
        assertEq(updatedListing.currency, listingParams.currency);
        assertEq(updatedListing.pricePerToken, listingParams.pricePerToken);
        assertEq(updatedListing.endTimestamp, listingParams.endTimestamp);
        assertEq(updatedListing.startTimestamp, listingParams.startTimestamp);
        assertEq(updatedListing.listingCreator, seller);
        assertEq(updatedListing.reserved, true);
        assertEq(uint256(updatedListing.status), 1); // Status.CREATED
        assertEq(uint256(updatedListing.tokenType), 0); // TokenType.ERC721
    }
}
