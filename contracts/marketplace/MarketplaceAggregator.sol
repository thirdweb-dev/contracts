// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IMarketplace.sol";

contract MarketplaceAggregator {
    /// @notice Emitted when a new listing is created.
    event NewListing(
        address indexed marketplace,
        address indexed listingCreator,
        uint256 indexed listingId,
        address assetContract,
        IDirectListings.Listing listing
    );

    function emitNewListing(
        address listingCreator,
        uint256 listingId,
        address assetContract,
        IDirectListings.Listing memory listing
    ) public {
        emit NewListing(msg.sender, listingCreator, listingId, assetContract, listing);
    }

    /// @notice Emitted when a listing is updated.
    event UpdatedListing(
        address indexed marketplace,
        address indexed listingCreator,
        uint256 indexed listingId,
        address assetContract,
        IDirectListings.Listing listing
    );

    function emitUpdateListing(
        address listingCreator,
        uint256 listingId,
        address assetContract,
        IDirectListings.Listing memory listing
    ) public {
        emit UpdatedListing(msg.sender, listingCreator, listingId, assetContract, listing);
    }

    /// @notice Emitted when a listing is cancelled.
    event CancelledListing(address indexed marketplace, address indexed listingCreator, uint256 indexed listingId);

    function emitCancelListing(address listingCreator, uint256 listingId) public {
        emit CancelledListing(msg.sender, listingCreator, listingId);
    }

    /// @notice Emitted when a buyer is approved to buy from a reserved listing.
    event BuyerApprovedForListing(
        address indexed marketplace,
        uint256 indexed listingId,
        address indexed buyer,
        bool approved
    );

    function emitBuyerApprovedForListing(
        uint256 listingId,
        address buyer,
        bool approved
    ) public {
        emit BuyerApprovedForListing(msg.sender, listingId, buyer, approved);
    }

    /// @notice Emitted when a currency is approved as a form of payment for the listing.
    event CurrencyApprovedForListing(
        address indexed marketplace,
        uint256 indexed listingId,
        address indexed currency,
        uint256 pricePerToken
    );

    function emitCurrencyApprovedForListing(
        uint256 listingId,
        address currency,
        uint256 pricePerToken
    ) public {
        emit CurrencyApprovedForListing(msg.sender, listingId, currency, pricePerToken);
    }

    /// @notice Emitted when NFTs are bought from a listing.
    event NewSale(
        address indexed marketplace,
        address indexed listingCreator,
        uint256 indexed listingId,
        address assetContract,
        uint256 tokenId,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    function emitNewSale(
        address listingCreator,
        uint256 listingId,
        address assetContract,
        uint256 tokenId,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    ) public {
        emit NewSale(
            msg.sender,
            listingCreator,
            listingId,
            assetContract,
            tokenId,
            buyer,
            quantityBought,
            totalPricePaid
        );
    }

    /// @dev Emitted when a new auction is created.
    event NewAuction(
        address indexed marketplace,
        address indexed auctionCreator,
        uint256 indexed auctionId,
        address assetContract,
        IEnglishAuctions.Auction auction
    );

    function emitNewAuction(
        address auctionCreator,
        uint256 auctionId,
        address assetContract,
        IEnglishAuctions.Auction memory auction
    ) public {
        emit NewAuction(msg.sender, auctionCreator, auctionId, assetContract, auction);
    }

    /// @dev Emitted when a new bid is made in an auction.
    event NewBid(
        address indexed marketplace,
        uint256 indexed auctionId,
        address indexed bidder,
        address assetContract,
        uint256 bidAmount,
        IEnglishAuctions.Auction auction
    );

    function emitNewBid(
        uint256 auctionId,
        address bidder,
        address assetContract,
        uint256 bidAmount,
        IEnglishAuctions.Auction memory auction
    ) public {
        emit NewBid(msg.sender, auctionId, bidder, assetContract, bidAmount, auction);
    }

    /// @notice Emitted when a auction is cancelled.
    event CancelledAuction(address indexed marketplace, address indexed auctionCreator, uint256 indexed auctionId);

    function emitCancelAuction(address auctionCreator, uint256 auctionId) public {
        emit CancelledAuction(msg.sender, auctionCreator, auctionId);
    }

    /// @dev Emitted when an auction is closed.
    event AuctionClosed(
        address indexed marketplace,
        uint256 indexed auctionId,
        address indexed assetContract,
        address closer,
        uint256 tokenId,
        address auctionCreator,
        address winningBidder
    );

    function emitAuctionClosed(
        uint256 auctionId,
        address assetContract,
        address closer,
        uint256 tokenId,
        address auctionCreator,
        address winningBidder
    ) public {
        emit AuctionClosed(msg.sender, auctionId, assetContract, closer, tokenId, auctionCreator, winningBidder);
    }

    /// @dev Emitted when a new offer is created.
    event NewOffer(
        address indexed marketplace,
        address indexed offeror,
        uint256 indexed offerId,
        address assetContract,
        IOffers.Offer offer
    );

    function emitNewOffer(
        address offeror,
        uint256 offerId,
        address assetContract,
        IOffers.Offer memory offer
    ) public {
        emit NewOffer(msg.sender, offeror, offerId, assetContract, offer);
    }

    /// @dev Emitted when an offer is cancelled.
    event CancelledOffer(address indexed marketplace, address indexed offeror, uint256 indexed offerId);

    function emitCancelOffer(address offeror, uint256 offerId) public {
        emit CancelledOffer(msg.sender, offeror, offerId);
    }

    /// @dev Emitted when an offer is accepted.
    event AcceptedOffer(
        address indexed marketplace,
        address indexed offeror,
        uint256 indexed offerId,
        address assetContract,
        uint256 tokenId,
        address seller,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    function emitAcceptedOffer(
        address offeror,
        uint256 offerId,
        address assetContract,
        uint256 tokenId,
        address seller,
        uint256 quantityBought,
        uint256 totalPricePaid
    ) public {
        emit AcceptedOffer(
            msg.sender,
            offeror,
            offerId,
            assetContract,
            tokenId,
            seller,
            quantityBought,
            totalPricePaid
        );
    }
}
