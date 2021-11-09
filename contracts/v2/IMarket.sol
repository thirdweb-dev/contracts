// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IMarket {

    /// @dev Type of the token listed.
    enum TokenType {
        ERC1155,
        ERC721
    }

    /// @dev Type of the listing
    enum ListingType {
        Direct,
        Auction
    }

    /// @dev The total info related to an offer on a direct listing.
    struct Offer {
        uint256 listingId;
        uint256 quantityWanted;
        uint256 offerAmount;
    }

    /// @dev The total info related to a listing.
    struct Listing {
        uint256 listingId;

        address tokenOwner;
        address assetContract;
        uint256 tokenId;

        uint256 startTime;
        uint256 endTime;

        uint256 quantity;
        address currency;

        uint256 reservePricePerToken;
        uint256 buyoutPricePerToken;
        uint256 tokensPerBuyer;

        uint256 currentHighestBid;
        address bidder;
        
        TokenType tokenType;
        ListingType listingType;
    }

    //  =====   Direct listing actions  =====   

    /// @dev Lets a token owner list tokens for sale: Direct Listing.
    function createListing(
        address _assetContract,
        uint256 _tokenId,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        uint256 _tokensPerBuyer,
        uint256 _quantityToList,
        address _currencyToAccept,
        uint256 _secondsUntilStartTime,
        uint256 _secondsUntilEndTime,
        ListingType listingType
    ) external;

    /// @dev Lets a listing's creator edit the quantity of tokens listed.
    function editListingQuantity(uint256 _listingId, uint256 _quantity) external;

    /// @dev Lets a listing's creator edit the listing's parameters.
    function editListingParametrs(        
        uint256 _listingId,
        uint256 _buyoutPricePerToken,
        uint256 _tokensPerBuyer,
        address _currencyToAccept,
        uint256 _secondsUntilStartTime,
        uint256 _secondsUntilEndTime
    ) external;

    /// @dev Lets an account buy a given quantity of tokens from a listing.
    function buy(uint256 _listingId, uint256 _quantity) external;

    /// @dev Lets an account offer a price for a given amount of tokens.
    function offer(
        uint256 _listingId, 
        uint256 _quantityWanted, 
        uint256 _totalOfferAmount
    ) external;

    /// @dev Lets an account bid on an existing auction.
    function bid(uint256 _listingId, uint256 _bidAmount) external;

    /// @dev Lets a listing's creator accept an offer for their direct listing.
    function acceptOffer(uint256 _listingId, address offeror) external;

    /// @dev Lets an auction's creator cancel the auction.
    function cancelAuction(uint256 _listingId) external;

    /// @dev Lets an auction's creator cancel the auction.
    function closeAuction(uint256 _listingId) external;
}