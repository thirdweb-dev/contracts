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

    /// @dev The total info related to a listing.
    struct Listing {
        uint256 listingId;

        address tokenOwner;
        address assetContract;
        uint256 tokenId;

        uint256 startTime;
        uint256 expireTime;

        uint256 quantity;
        address currency;
        
        ListingType listingType;
        TokenType tokenType;

        // specific: Direct
        uint256 pricePerToken;
        uint256 tokensPerBuyer;

        // specific: Auction
        uint256 reservePrice;
        uint256 buyoutPrice;
        uint256 currentBid;
        uint256 bidder;
    }

    //  =====   Direct listing actions  =====   

    /// @dev Lets a token owner list tokens for sale: Direct Listing.
    function createListing(
        address _assetContract,
        uint256 _tokenId,
        address _currency,
        uint256 _pricePerToken,
        uint256 _quantity,
        uint256 _tokensPerBuyer,
        uint256 _secondsUntilStartTime,
        uint256 _secondsUntilEndTIme
    ) external;

    /// @dev Lets a listing's creator edit the quantity of tokens listed.
    function editListingQuantity(uint256 _listingId, uint256 _quantity) external;

    /// @dev Lets a listing's creator edit the listing's parameters.
    function editListingParametrs(
        uint256 _listingId,
        uint256 _pricePerToken,
        address _currency,
        uint256 _tokensPerBuyer,
        uint256 _secondsUntilStart,
        uint256 _secondsUntilEnd
    ) external;

    /// @dev Lets an account buy a given quantity of tokens from a listing.
    function buy(uint256 _listingId, uint256 _quantity) external;

    /// @dev Lets an account offer a price for a given amount of tokens.
    function offer(
        uint256 _listingId, 
        uint256 _quantityWanted, 
        uint256 _totalOfferAmount
    ) external;

    /// @dev Lets a listing's creator accept an offer for their direct listing.
    function acceptOffer(uint256 _offerId) external;

    //  ===== Auction actions   =====

    /// @dev Lets a token owner put up their tokens for auction.
    function createAuction(
        address _assetContract,
        uint256 _tokenId,
        address _currency,        
        uint256 _quantity,
        uint256 _reservePrice,
        uint256 _buyoutPrice,
        uint256 _secondsUntilStartTime,
        uint256 _secondsUntilEndTIme
    ) external;

    /// @dev Lets an auction's creator cancel the auction.
    function cancelAuction(uint256 _listingId) external;

    /// @dev Lets an account bid on an existing auction.
    function createBid(uint256 _listingId, uint256 _bidAmount) external;
}