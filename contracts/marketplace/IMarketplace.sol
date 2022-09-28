// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IDirectListings {
    enum TokenType {
        ERC721,
        ERC1155
    }

    struct ListingParameters {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint128 startTimestamp;
        uint128 endTimestamp;
        bool reserved;
    }

    struct Listing {
        uint256 listingId;
        address listingCreator;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint128 startTimestamp;
        uint128 endTimestamp;
        bool reserved;
        TokenType tokenType;
    }

    event NewListing(address indexed listingCreator, uint256 indexed listingId, Listing listing);
    event UpdatedListing(address indexed listingCreator, uint256 indexed listingId, Listing listing);
    event CancelledListing(address indexed listingCreator, uint256 indexed listingId);
    event ApprovalForListing(uint256 indexed listingId, address indexed buyer, bool approved);
    event CurrencyPriceForListing(
        uint256 indexed listingId,
        address indexed currency,
        uint256 pricePerToken,
        bool approved
    );

    function createListing(ListingParameters memory _params) external returns (uint256 listingId);

    function updateListing(uint256 _listingId, ListingParameters memory _params) external;

    function cancelListing(uint256 _listingId) external;

    function approveBuyerForLisitng(
        uint256 _listingId,
        address _buyer,
        bool _toApprove
    ) external;

    function approveCurrencyForLisitng(
        uint256 _listingId,
        address _currency,
        uint256 _pricePerTokenInCurrency,
        bool _toApprove
    ) external;

    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _totalPrice
    ) external payable;

    function getAllListings() external view returns (Listing[] memory listings);

    function getListing(uint256 _listingId) external view returns (Listing memory listing);
}

interface IEnglishAuctions {
    enum TokenType {
        ERC721,
        ERC1155
    }

    struct AuctionParameters {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 minimumBidAmount;
        uint256 buyoutBidAmount;
        uint64 timeBufferInSeconds;
        uint64 bidBufferBps;
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    struct Auction {
        uint256 auctionId;
        address auctionCreator;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 minimumBidAmount;
        uint256 buyoutBidAmount;
        uint64 timeBufferInSeconds;
        uint64 bidBufferBps;
        uint64 startTimestamp;
        uint64 endTimestamp;
        TokenType tokenType;
    }

    struct Bid {
        uint256 auctionId;
        address bidder;
        uint256 bidAmount;
    }

    /// @dev Emitted when a new auction is created.
    event NewAuction(address indexed auctionCreator, uint256 indexed auctionId, Auction auction);

    /// @dev Emitted when a new bid is made in an auction.
    event NewBid(uint256 indexed auctionId, address indexed bidder, uint256 bidAmount);

    /// @dev Emitted when an auction is closed.
    event AuctionClosed(
        uint256 indexed auctionId,
        address indexed closer,
        bool indexed cancelled,
        address auctionCreator,
        address winningBidder
    );

    function createAuction(AuctionParameters memory _params) external returns (uint256 auctionId);

    function cancelAuction(uint256 _auctionId) external;

    function collectAuctionPayout(uint256 _auctionId) external;

    function collectAuctionTokens(uint256 _auctionId) external;

    function bidInAuction(uint256 _auctionId, uint256 _bidAmount) external payable;

    function isNewWinningBid(uint256 _auctionId, uint256 _bidAmount) external view returns (bool);

    function getAuction(uint256 _auctionId) external view returns (Auction memory auction);

    function getAllAuctions() external view returns (Auction[] memory auctions);

    function getWinningBid(uint256 _auctionId)
        external
        view
        returns (
            address bidder,
            address currency,
            uint256 bidAmount
        );

    function isAuctionExpired(uint256 _auctionId) external view returns (bool);
}

interface IOffers {
    enum TokenType {
        ERC721,
        ERC1155
    }

    struct OfferParams {
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 totalPrice;
        uint256 expirationTimestamp;
    }

    struct Offer {
        uint256 offerId;
        address offeror;
        address assetContract;
        uint256 tokenId;
        TokenType tokenType;
        uint256 quantity;
        address currency;
        uint256 totalPrice;
        uint256 expirationTimestamp;
    }

    function makeOffer(OfferParams memory _params) external returns (uint256 offerId);

    function cancelOffer(uint256 _offerId) external;

    function acceptOffer(uint256 _offerId) external;

    function getOffer(uint256 _offerId) external view returns (Offer memory offer);

    function getAllOffers(uint256 _offerId) external view returns (Offer[] memory offers);
}
