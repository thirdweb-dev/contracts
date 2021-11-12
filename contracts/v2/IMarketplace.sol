// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IMarketplace {

    /// @dev Type of the token listed.
    enum TokenType {
        ERC1155,
        ERC721
    }

    /// @dev The total info related to an offer on a direct listing.
    struct Offer {
        uint256 listingId;
        address offeror;
        uint256 quantityWanted;
        uint256 offerAmount;
    }

    /// @dev For use in `createListing` as a parameter type.
    struct ListingParameters {
        address assetContract;
        uint256 tokenId;

        uint256 secondsUntilStartTime;
        uint256 secondsUntilEndTime;

        uint256 quantityToList;
        address currencyToAccept;

        uint256 buyoutPricePerToken;
        uint256 tokensPerBuyer;
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

        uint256 buyoutPricePerToken;
        uint256 tokensPerBuyer;
        
        TokenType tokenType;
    }

    /// @dev Emitted when a new listing is created.
    event NewListing(
        address indexed assetContract, 
        address indexed seller, 
        uint256 indexed listingId, 
        Listing listing
    );

    /// @dev Emitted when a listing is updated.
    event ListingUpdate(
        address indexed listingCreator, 
        uint256 indexed listingId, 
        Listing listing
    );

    /// @dev Emitted on a sale from a direct listing
    event NewDirectSale(
        address indexed assetContract,
        address indexed seller,
        uint256 indexed listingId,
        address buyer,
        uint256 quantity,
        Listing listing
    );

    /// @dev Emitted when a new offer is made to a direct listing.
    event NewOffer(uint256 indexed listingId, address indexed offeror, Offer offer, Listing listing);

    /// @dev Emitted when market fee is updated.
    event MarketFeeUpdate(uint128 newFee);

    /// @dev Emitted when LISTER_ROLE restriction is updated.
    event RestrictedListerRoleUpdated(bool restricted);   

    /// @dev Lets a token owner list tokens for sale: Direct Listing.
    function createListing(
        ListingParameters memory _params
    ) external;

    /// @dev Lets a listing's creator edit the listing's parameters.
    function editListingParametrs(    
        uint256 _listingId,
        uint256 _quantityToList,
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

    /// @dev Lets a listing's creator accept an offer for their direct listing.
    function acceptOffer(uint256 _listingId, address offeror) external;
}