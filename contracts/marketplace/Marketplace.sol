// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import { IMarketplace } from "../interfaces/marketplace/IMarketplace.sol";

import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "../lib/CurrencyTransferLib.sol";
import "../lib/FeeType.sol";

contract Marketplace is
    Initializable,
    IMarketplace,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("Marketplace");
    uint256 private constant VERSION = 2;

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /// @dev Total number of listings ever created in the marketplace.
    uint256 public totalListings;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

    /// @dev The % of primary sales collected as platform fees.
    uint64 private platformFeeBps;

    /// @dev
    /**
     *  @dev The amount of time added to an auction's 'endTime', if a bid is made within `timeBuffer`
     *       seconds of the existing `endTime`. Default: 15 minutes.
     */
    uint64 public timeBuffer;

    /// @dev The minimum % increase required from the previous winning bid. Default: 5%.
    uint64 public bidBufferBps;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from uid of listing => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev Mapping from uid of a direct listing => offeror address => offer made to the direct listing by the respective offeror.
    mapping(uint256 => mapping(address => Offer)) public offers;

    /// @dev Mapping from uid of an auction listing => current winning bid in an auction.
    mapping(uint256 => Offer) public winningBid;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether caller is a listing creator.
    modifier onlyListingCreator(uint256 _listingId) {
        require(listings[_listingId].tokenOwner == _msgSender(), "!OWNER");
        _;
    }

    /// @dev Checks whether a listing exists.
    modifier onlyExistingListing(uint256 _listingId) {
        require(listings[_listingId].assetContract != address(0), "DNE");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper) initializer {
        nativeTokenWrapper = _nativeTokenWrapper;
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _platformFeeRecipient,
        uint256 _platformFeeBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);

        // Initialize this contract's state.
        timeBuffer = 15 minutes;
        bidBufferBps = 500;

        contractURI = _contractURI;
        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(LISTER_ROLE, address(0));
        _setupRole(ASSET_ROLE, address(0));
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets the contract receives native tokens from `nativeTokenWrapper` withdraw.
    receive() external payable {}

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 1155 logic
    //////////////////////////////////////////////////////////////*/

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                Listing (create-update-delete) logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a token owner list tokens for sale: Direct Listing or Auction.
    function createListing(ListingParameters memory _params) external override {
        // Get values to populate `Listing`.
        uint256 listingId = totalListings;
        totalListings += 1;

        address tokenOwner = _msgSender();
        TokenType tokenTypeOfListing = getTokenType(_params.assetContract);
        uint256 tokenAmountToList = getSafeQuantity(tokenTypeOfListing, _params.quantityToList);

        require(tokenAmountToList > 0, "QUANTITY");
        require(hasRole(LISTER_ROLE, address(0)) || hasRole(LISTER_ROLE, _msgSender()), "!LISTER");
        require(hasRole(ASSET_ROLE, address(0)) || hasRole(ASSET_ROLE, _params.assetContract), "!ASSET");

        uint256 startTime = _params.startTime;
        if (startTime < block.timestamp) {
            // do not allow listing to start in the past (1 hour buffer)
            require(block.timestamp - startTime < 1 hours, "ST");
            startTime = block.timestamp;
        }

        validateOwnershipAndApproval(
            tokenOwner,
            _params.assetContract,
            _params.tokenId,
            tokenAmountToList,
            tokenTypeOfListing
        );

        Listing memory newListing = Listing({
            listingId: listingId,
            tokenOwner: tokenOwner,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            startTime: startTime,
            endTime: startTime + _params.secondsUntilEndTime,
            quantity: tokenAmountToList,
            currency: _params.currencyToAccept,
            reservePricePerToken: _params.reservePricePerToken,
            buyoutPricePerToken: _params.buyoutPricePerToken,
            tokenType: tokenTypeOfListing,
            listingType: _params.listingType
        });

        listings[listingId] = newListing;

        // Tokens listed for sale in an auction are escrowed in Marketplace.
        if (newListing.listingType == ListingType.Auction) {
            require(newListing.buyoutPricePerToken >= newListing.reservePricePerToken, "RESERVE");
            transferListingTokens(tokenOwner, address(this), tokenAmountToList, newListing);
        }

        emit ListingAdded(listingId, _params.assetContract, tokenOwner, newListing);
    }

    /// @dev Lets a listing's creator edit the listing's parameters.
    function updateListing(
        uint256 _listingId,
        uint256 _quantityToList,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        address _currencyToAccept,
        uint256 _startTime,
        uint256 _secondsUntilEndTime
    ) external override onlyListingCreator(_listingId) {
        Listing memory targetListing = listings[_listingId];
        uint256 safeNewQuantity = getSafeQuantity(targetListing.tokenType, _quantityToList);
        bool isAuction = targetListing.listingType == ListingType.Auction;

        require(safeNewQuantity != 0, "QUANTITY");

        // Can only edit auction listing before it starts.
        if (isAuction) {
            require(block.timestamp < targetListing.startTime, "STARTED");
            require(_buyoutPricePerToken >= _reservePricePerToken, "RESERVE");
        }

        if (_startTime < block.timestamp) {
            // do not allow listing to start in the past (1 hour buffer)
            require(block.timestamp - _startTime < 1 hours, "ST");
            _startTime = block.timestamp;
        }

        uint256 newStartTime = _startTime == 0 ? targetListing.startTime : _startTime;
        listings[_listingId] = Listing({
            listingId: _listingId,
            tokenOwner: _msgSender(),
            assetContract: targetListing.assetContract,
            tokenId: targetListing.tokenId,
            startTime: newStartTime,
            endTime: _secondsUntilEndTime == 0 ? targetListing.endTime : newStartTime + _secondsUntilEndTime,
            quantity: safeNewQuantity,
            currency: _currencyToAccept,
            reservePricePerToken: _reservePricePerToken,
            buyoutPricePerToken: _buyoutPricePerToken,
            tokenType: targetListing.tokenType,
            listingType: targetListing.listingType
        });

        // Must validate ownership and approval of the new quantity of tokens for diret listing.
        if (targetListing.quantity != safeNewQuantity) {
            // Transfer all escrowed tokens back to the lister, to be reflected in the lister's
            // balance for the upcoming ownership and approval check.
            if (isAuction) {
                transferListingTokens(address(this), targetListing.tokenOwner, targetListing.quantity, targetListing);
            }

            validateOwnershipAndApproval(
                targetListing.tokenOwner,
                targetListing.assetContract,
                targetListing.tokenId,
                safeNewQuantity,
                targetListing.tokenType
            );

            // Escrow the new quantity of tokens to list in the auction.
            if (isAuction) {
                transferListingTokens(targetListing.tokenOwner, address(this), safeNewQuantity, targetListing);
            }
        }

        emit ListingUpdated(_listingId, targetListing.tokenOwner);
    }

    /// @dev Lets a direct listing creator cancel their listing.
    function cancelDirectListing(uint256 _listingId) external onlyListingCreator(_listingId) {
        Listing memory targetListing = listings[_listingId];

        require(targetListing.listingType == ListingType.Direct, "!DIRECT");

        delete listings[_listingId];

        emit ListingRemoved(_listingId, targetListing.tokenOwner);
    }

    /*///////////////////////////////////////////////////////////////
                    Direct lisitngs sales logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account buy a given quantity of tokens from a listing.
    function buy(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantityToBuy,
        address _currency,
        uint256 _totalPrice
    ) external payable override nonReentrant onlyExistingListing(_listingId) {
        Listing memory targetListing = listings[_listingId];
        address payer = _msgSender();

        // Check whether the settled total price and currency to use are correct.
        require(
            _currency == targetListing.currency && _totalPrice == (targetListing.buyoutPricePerToken * _quantityToBuy),
            "!PRICE"
        );

        executeSale(
            targetListing,
            payer,
            _buyFor,
            targetListing.currency,
            targetListing.buyoutPricePerToken * _quantityToBuy,
            _quantityToBuy
        );
    }

    /// @dev Lets a listing's creator accept an offer for their direct listing.
    function acceptOffer(
        uint256 _listingId,
        address _offeror,
        address _currency,
        uint256 _pricePerToken
    ) external override nonReentrant onlyListingCreator(_listingId) onlyExistingListing(_listingId) {
        Offer memory targetOffer = offers[_listingId][_offeror];
        Listing memory targetListing = listings[_listingId];

        require(_currency == targetOffer.currency && _pricePerToken == targetOffer.pricePerToken, "!PRICE");
        require(targetOffer.expirationTimestamp > block.timestamp, "EXPIRED");

        delete offers[_listingId][_offeror];

        executeSale(
            targetListing,
            _offeror,
            _offeror,
            targetOffer.currency,
            targetOffer.pricePerToken * targetOffer.quantityWanted,
            targetOffer.quantityWanted
        );
    }

    /// @dev Performs a direct listing sale.
    function executeSale(
        Listing memory _targetListing,
        address _payer,
        address _receiver,
        address _currency,
        uint256 _currencyAmountToTransfer,
        uint256 _listingTokenAmountToTransfer
    ) internal {
        validateDirectListingSale(
            _targetListing,
            _payer,
            _listingTokenAmountToTransfer,
            _currency,
            _currencyAmountToTransfer
        );

        _targetListing.quantity -= _listingTokenAmountToTransfer;
        listings[_targetListing.listingId] = _targetListing;

        payout(_payer, _targetListing.tokenOwner, _currency, _currencyAmountToTransfer, _targetListing);
        transferListingTokens(_targetListing.tokenOwner, _receiver, _listingTokenAmountToTransfer, _targetListing);

        emit NewSale(
            _targetListing.listingId,
            _targetListing.assetContract,
            _targetListing.tokenOwner,
            _receiver,
            _listingTokenAmountToTransfer,
            _currencyAmountToTransfer
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Offer/bid logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account (1) make an offer to a direct listing, or (2) make a bid in an auction.
    function offer(
        uint256 _listingId,
        uint256 _quantityWanted,
        address _currency,
        uint256 _pricePerToken,
        uint256 _expirationTimestamp
    ) external payable override nonReentrant onlyExistingListing(_listingId) {
        Listing memory targetListing = listings[_listingId];

        require(
            targetListing.endTime > block.timestamp && targetListing.startTime < block.timestamp,
            "inactive listing."
        );

        // Both - (1) offers to direct listings, and (2) bids to auctions - share the same structure.
        Offer memory newOffer = Offer({
            listingId: _listingId,
            offeror: _msgSender(),
            quantityWanted: _quantityWanted,
            currency: _currency,
            pricePerToken: _pricePerToken,
            expirationTimestamp: _expirationTimestamp
        });

        if (targetListing.listingType == ListingType.Auction) {
            // A bid to an auction must be made in the auction's desired currency.
            require(newOffer.currency == targetListing.currency, "must use approved currency to bid");

            // A bid must be made for all auction items.
            newOffer.quantityWanted = getSafeQuantity(targetListing.tokenType, targetListing.quantity);

            handleBid(targetListing, newOffer);
        } else if (targetListing.listingType == ListingType.Direct) {
            // Prevent potentially lost/locked native token.
            require(msg.value == 0, "no value needed");

            // Offers to direct listings cannot be made directly in native tokens.
            newOffer.currency = _currency == CurrencyTransferLib.NATIVE_TOKEN ? nativeTokenWrapper : _currency;
            newOffer.quantityWanted = getSafeQuantity(targetListing.tokenType, _quantityWanted);

            handleOffer(targetListing, newOffer);
        }
    }

    /// @dev Processes a new offer to a direct listing.
    function handleOffer(Listing memory _targetListing, Offer memory _newOffer) internal {
        require(
            _newOffer.quantityWanted <= _targetListing.quantity && _targetListing.quantity > 0,
            "insufficient tokens in listing."
        );

        validateERC20BalAndAllowance(
            _newOffer.offeror,
            _newOffer.currency,
            _newOffer.pricePerToken * _newOffer.quantityWanted
        );

        offers[_targetListing.listingId][_newOffer.offeror] = _newOffer;

        emit NewOffer(
            _targetListing.listingId,
            _newOffer.offeror,
            _targetListing.listingType,
            _newOffer.quantityWanted,
            _newOffer.pricePerToken * _newOffer.quantityWanted,
            _newOffer.currency
        );
    }

    /// @dev Processes an incoming bid in an auction.
    function handleBid(Listing memory _targetListing, Offer memory _incomingBid) internal {
        Offer memory currentWinningBid = winningBid[_targetListing.listingId];
        uint256 currentOfferAmount = currentWinningBid.pricePerToken * currentWinningBid.quantityWanted;
        uint256 incomingOfferAmount = _incomingBid.pricePerToken * _incomingBid.quantityWanted;
        address _nativeTokenWrapper = nativeTokenWrapper;

        // Close auction and execute sale if there's a buyout price and incoming offer amount is buyout price.
        if (
            _targetListing.buyoutPricePerToken > 0 &&
            incomingOfferAmount >= _targetListing.buyoutPricePerToken * _targetListing.quantity
        ) {
            _closeAuctionForBidder(_targetListing, _incomingBid);
        } else {
            /**
             *      If there's an exisitng winning bid, incoming bid amount must be bid buffer % greater.
             *      Else, bid amount must be at least as great as reserve price
             */
            require(
                isNewWinningBid(
                    _targetListing.reservePricePerToken * _targetListing.quantity,
                    currentOfferAmount,
                    incomingOfferAmount
                ),
                "not winning bid."
            );

            // Update the winning bid and listing's end time before external contract calls.
            winningBid[_targetListing.listingId] = _incomingBid;

            if (_targetListing.endTime - block.timestamp <= timeBuffer) {
                _targetListing.endTime += timeBuffer;
                listings[_targetListing.listingId] = _targetListing;
            }
        }

        // Payout previous highest bid.
        if (currentWinningBid.offeror != address(0) && currentOfferAmount > 0) {
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _targetListing.currency,
                address(this),
                currentWinningBid.offeror,
                currentOfferAmount,
                _nativeTokenWrapper
            );
        }

        // Collect incoming bid
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _targetListing.currency,
            _incomingBid.offeror,
            address(this),
            incomingOfferAmount,
            _nativeTokenWrapper
        );

        emit NewOffer(
            _targetListing.listingId,
            _incomingBid.offeror,
            _targetListing.listingType,
            _incomingBid.quantityWanted,
            _incomingBid.pricePerToken * _incomingBid.quantityWanted,
            _incomingBid.currency
        );
    }

    /// @dev Checks whether an incoming bid is the new current highest bid.
    function isNewWinningBid(
        uint256 _reserveAmount,
        uint256 _currentWinningBidAmount,
        uint256 _incomingBidAmount
    ) internal view returns (bool isValidNewBid) {
        if (_currentWinningBidAmount == 0) {
            isValidNewBid = _incomingBidAmount >= _reserveAmount;
        } else {
            isValidNewBid = (_incomingBidAmount > _currentWinningBidAmount &&
                ((_incomingBidAmount - _currentWinningBidAmount) * MAX_BPS) / _currentWinningBidAmount >= bidBufferBps);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Auction lisitngs sales logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account close an auction for either the (1) winning bidder, or (2) auction creator.
    function closeAuction(uint256 _listingId, address _closeFor)
        external
        override
        nonReentrant
        onlyExistingListing(_listingId)
    {
        Listing memory targetListing = listings[_listingId];

        require(targetListing.listingType == ListingType.Auction, "not an auction.");

        Offer memory targetBid = winningBid[_listingId];

        // Cancel auction if (1) auction hasn't started, or (2) auction doesn't have any bids.
        bool toCancel = targetListing.startTime > block.timestamp || targetBid.offeror == address(0);

        if (toCancel) {
            // cancel auction listing owner check
            _cancelAuction(targetListing);
        } else {
            require(targetListing.endTime < block.timestamp, "cannot close auction before it has ended.");

            // No `else if` to let auction close in 1 tx when targetListing.tokenOwner == targetBid.offeror.
            if (_closeFor == targetListing.tokenOwner) {
                _closeAuctionForAuctionCreator(targetListing, targetBid);
            }

            if (_closeFor == targetBid.offeror) {
                _closeAuctionForBidder(targetListing, targetBid);
            }
        }
    }

    /// @dev Cancels an auction.
    function _cancelAuction(Listing memory _targetListing) internal {
        require(listings[_targetListing.listingId].tokenOwner == _msgSender(), "caller is not the listing creator.");

        delete listings[_targetListing.listingId];

        transferListingTokens(address(this), _targetListing.tokenOwner, _targetListing.quantity, _targetListing);

        emit AuctionClosed(_targetListing.listingId, _msgSender(), true, _targetListing.tokenOwner, address(0));
    }

    /// @dev Closes an auction for an auction creator; distributes winning bid amount to auction creator.
    function _closeAuctionForAuctionCreator(Listing memory _targetListing, Offer memory _winningBid) internal {
        uint256 payoutAmount = _winningBid.pricePerToken * _targetListing.quantity;

        _targetListing.quantity = 0;
        _targetListing.endTime = block.timestamp;
        listings[_targetListing.listingId] = _targetListing;

        _winningBid.pricePerToken = 0;
        winningBid[_targetListing.listingId] = _winningBid;

        payout(address(this), _targetListing.tokenOwner, _targetListing.currency, payoutAmount, _targetListing);

        emit AuctionClosed(
            _targetListing.listingId,
            _msgSender(),
            false,
            _targetListing.tokenOwner,
            _winningBid.offeror
        );
    }

    /// @dev Closes an auction for the winning bidder; distributes auction items to the winning bidder.
    function _closeAuctionForBidder(Listing memory _targetListing, Offer memory _winningBid) internal {
        uint256 quantityToSend = _winningBid.quantityWanted;

        _targetListing.endTime = block.timestamp;
        _winningBid.quantityWanted = 0;

        winningBid[_targetListing.listingId] = _winningBid;
        listings[_targetListing.listingId] = _targetListing;

        transferListingTokens(address(this), _winningBid.offeror, quantityToSend, _targetListing);

        emit AuctionClosed(
            _targetListing.listingId,
            _msgSender(),
            false,
            _targetListing.tokenOwner,
            _winningBid.offeror
        );
    }

    /*///////////////////////////////////////////////////////////////
            Shared (direct+auction listings) internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Transfers tokens listed for sale in a direct or auction listing.
    function transferListingTokens(
        address _from,
        address _to,
        uint256 _quantity,
        Listing memory _listing
    ) internal {
        if (_listing.tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, _quantity, "");
        } else if (_listing.tokenType == TokenType.ERC721) {
            IERC721Upgradeable(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, "");
        }
    }

    /// @dev Pays out stakeholders in a sale.
    function payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Listing memory _listing
    ) internal {
        uint256 platformFeeCut = (_totalPayoutAmount * platformFeeBps) / MAX_BPS;

        uint256 royaltyCut;
        address royaltyRecipient;

        // Distribute royalties. See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
        try IERC2981Upgradeable(_listing.assetContract).royaltyInfo(_listing.tokenId, _totalPayoutAmount) returns (
            address royaltyFeeRecipient,
            uint256 royaltyFeeAmount
        ) {
            if (royaltyFeeRecipient != address(0) && royaltyFeeAmount > 0) {
                require(royaltyFeeAmount + platformFeeCut <= _totalPayoutAmount, "fees exceed the price");
                royaltyRecipient = royaltyFeeRecipient;
                royaltyCut = royaltyFeeAmount;
            }
        } catch {}

        // Distribute price to token owner
        address _nativeTokenWrapper = nativeTokenWrapper;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            platformFeeRecipient,
            platformFeeCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            royaltyRecipient,
            royaltyCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            _payee,
            _totalPayoutAmount - (platformFeeCut + royaltyCut),
            _nativeTokenWrapper
        );
    }

    /// @dev Validates that `_addrToCheck` owns and has approved markeplace to transfer the appropriate amount of currency
    function validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20Upgradeable(_currency).balanceOf(_addrToCheck) >= _currencyAmountToCheckAgainst &&
                IERC20Upgradeable(_currency).allowance(_addrToCheck, address(this)) >= _currencyAmountToCheckAgainst,
            "!BAL20"
        );
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Market to transfer NFTs.
    function validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view {
        address market = address(this);
        bool isValid;

        if (_tokenType == TokenType.ERC1155) {
            isValid =
                IERC1155Upgradeable(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity &&
                IERC1155Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, market);
        } else if (_tokenType == TokenType.ERC721) {
            isValid =
                IERC721Upgradeable(_assetContract).ownerOf(_tokenId) == _tokenOwner &&
                (IERC721Upgradeable(_assetContract).getApproved(_tokenId) == market ||
                    IERC721Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, market));
        }

        require(isValid, "!BALNFT");
    }

    /// @dev Validates conditions of a direct listing sale.
    function validateDirectListingSale(
        Listing memory _listing,
        address _payer,
        uint256 _quantityToBuy,
        address _currency,
        uint256 settledTotalPrice
    ) internal {
        require(_listing.listingType == ListingType.Direct, "cannot buy from listing.");

        // Check whether a valid quantity of listed tokens is being bought.
        require(
            _listing.quantity > 0 && _quantityToBuy > 0 && _quantityToBuy <= _listing.quantity,
            "invalid amount of tokens."
        );

        // Check if sale is made within the listing window.
        require(block.timestamp < _listing.endTime && block.timestamp > _listing.startTime, "not within sale window.");

        // Check: buyer owns and has approved sufficient currency for sale.
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == settledTotalPrice, "msg.value != price");
        } else {
            validateERC20BalAndAllowance(_payer, _currency, settledTotalPrice);
        }

        // Check whether token owner owns and has approved `quantityToBuy` amount of listing tokens from the listing.
        validateOwnershipAndApproval(
            _listing.tokenOwner,
            _listing.assetContract,
            _listing.tokenId,
            _quantityToBuy,
            _listing.tokenType
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Enforces quantity == 1 if tokenType is TokenType.ERC721.
    function getSafeQuantity(TokenType _tokenType, uint256 _quantityToCheck)
        internal
        pure
        returns (uint256 safeQuantity)
    {
        if (_quantityToCheck == 0) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721 ? 1 : _quantityToCheck;
        }
    }

    /// @dev Returns the interface supported by a contract.
    function getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
        if (IERC165Upgradeable(_assetContract).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {
            tokenType = TokenType.ERC1155;
        } else if (IERC165Upgradeable(_assetContract).supportsInterface(type(IERC721Upgradeable).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("token must be ERC1155 or ERC721.");
        }
    }

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /*///////////////////////////////////////////////////////////////
                            Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin update platform fee recipient and bps.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_platformFeeBps <= MAX_BPS, "bps <= 10000.");

        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin set auction buffers.
    function setAuctionBuffers(uint256 _timeBuffer, uint256 _bidBufferBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bidBufferBps < MAX_BPS, "invalid BPS.");

        timeBuffer = uint64(_timeBuffer);
        bidBufferBps = uint64(_bidBufferBps);

        emit AuctionBuffersUpdated(_timeBuffer, _bidBufferBps);
    }

    /// @dev Lets a contract admin set the URI for the contract-level metadata.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
