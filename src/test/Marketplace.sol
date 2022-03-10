// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/marketplace/Marketplace.sol";

// Test imports
import "./utils/BaseTest.sol";

contract MarketplaceTest is BaseTest {
    Marketplace public marketplace;

    Marketplace.ListingParameters public directListing;
    Marketplace.ListingParameters public auctionListing;

    function setUp() public override {
        super.setUp();
        marketplace = Marketplace(payable(getContract("Marketplace")));
    }

    function createERC721Listing(
        address to,
        address currency,
        uint256 price,
        IMarketplace.ListingType listingType
    ) public returns (uint256 listingId, Marketplace.ListingParameters memory listing) {
        uint256 tokenId = erc721.nextTokenIdToMint();
        erc721.mint(to, 1);
        vm.prank(to);
        erc721.setApprovalForAll(address(marketplace), true);

        listing.assetContract = address(erc721);
        listing.tokenId = tokenId;
        listing.startTime = 0;
        listing.secondsUntilEndTime = 1 * 24 * 60 * 60; // 1 day
        listing.quantityToList = 1;
        listing.currencyToAccept = currency;
        listing.reservePricePerToken = 0;
        listing.buyoutPricePerToken = price;
        listing.listingType = listingType;

        listingId = marketplace.totalListings();
        marketplace.createListing(listing);
    }

    function getListing(uint256 _listingId) public view returns (Marketplace.Listing memory listing) {
        (
            uint256 listingId,
            address tokenOwner,
            address assetContract,
            uint256 tokenId,
            uint256 startTime,
            uint256 endTime,
            uint256 quantity,
            address currency,
            uint256 reservePricePerToken,
            uint256 buyoutPricePerToken,
            IMarketplace.TokenType tokenType,
            IMarketplace.ListingType listingType
        ) = marketplace.listings(_listingId);
        listing.listingId = listingId;
        listing.tokenOwner = tokenOwner;
        listing.assetContract = assetContract;
        listing.tokenId = tokenId;
        listing.startTime = startTime;
        listing.endTime = endTime;
        listing.quantity = quantity;
        listing.currency = currency;
        listing.reservePricePerToken = reservePricePerToken;
        listing.buyoutPricePerToken = buyoutPricePerToken;
        listing.tokenType = tokenType;
        listing.listingType = listingType;
    }

    function getWinningBid(uint256 _listingId) public view returns (Marketplace.Offer memory winningBid) {
        (
            uint256 listingId,
            address offeror,
            uint256 quantityWanted,
            address currency,
            uint256 pricePerToken
        ) = marketplace.winningBid(_listingId);
        winningBid.listingId = listingId;
        winningBid.offeror = offeror;
        winningBid.quantityWanted = quantityWanted;
        winningBid.currency = currency;
        winningBid.pricePerToken = pricePerToken;
    }

    function test_createListing_auctionListing() public {
        vm.startPrank(getActor(0));
        (uint256 createdListingId, Marketplace.ListingParameters memory createdListing) = createERC721Listing(
            getActor(0),
            NATIVE_TOKEN,
            1 ether,
            IMarketplace.ListingType.Auction
        );

        Marketplace.Listing memory listing = getListing(createdListingId);
        assertEq(createdListingId, listing.listingId);
        assertEq(createdListing.assetContract, listing.assetContract);
        assertEq(createdListing.tokenId, listing.tokenId);
        assertEq(createdListing.startTime, listing.startTime);
        assertEq(createdListing.startTime + createdListing.secondsUntilEndTime, listing.endTime);
        assertEq(createdListing.quantityToList, listing.quantity);
        assertEq(createdListing.currencyToAccept, listing.currency);
        assertEq(createdListing.reservePricePerToken, listing.reservePricePerToken);
        assertEq(createdListing.buyoutPricePerToken, listing.buyoutPricePerToken);
        assertEq(uint8(IMarketplace.TokenType.ERC721), uint8(listing.tokenType));
        assertEq(uint8(IMarketplace.ListingType.Auction), uint8(listing.listingType));
    }

    function test_offer_bidAuctionNativeToken() public {
        vm.deal(getActor(0), 100 ether);
        vm.startPrank(getActor(0));

        Marketplace.Offer memory winningBid;
        (uint256 listingId, ) = createERC721Listing(
            getActor(0),
            NATIVE_TOKEN,
            123456 ether,
            IMarketplace.ListingType.Auction
        );

        assertEq(getActor(0).balance, 100 ether);

        vm.warp(1);
        marketplace.offer{ value: 1 ether }(listingId, 1, NATIVE_TOKEN, 1 ether);
        winningBid = getWinningBid(listingId);
        assertEq(getActor(0).balance, 99 ether);
        assertEq(winningBid.listingId, listingId);
        assertEq(winningBid.offeror, getActor(0));
        assertEq(winningBid.quantityWanted, 1);
        assertEq(winningBid.currency, NATIVE_TOKEN);
        assertEq(winningBid.pricePerToken, 1 ether);

        vm.warp(2);
        marketplace.offer{ value: 2 ether }(listingId, 1, NATIVE_TOKEN, 2 ether);
        winningBid = getWinningBid(listingId);
        assertEq(getActor(0).balance, 98 ether);
        assertEq(winningBid.listingId, listingId);
        assertEq(winningBid.offeror, getActor(0));
        assertEq(winningBid.quantityWanted, 1);
        assertEq(winningBid.currency, NATIVE_TOKEN);
        assertEq(winningBid.pricePerToken, 2 ether);
    }
}
