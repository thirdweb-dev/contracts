// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { IMarket } from "./IMarket.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Protocol control center.
import { ProtocolControl } from "../ProtocolControl.sol";

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// TODO: Variable size optimizations; general gas optimizations.

contract MarketWithAuction is
    IMarket,
    AccessControlEnumerable,
    IERC1155Receiver,
    IERC721Receiver,
    ReentrancyGuard,
    ERC2771Context,
    Multicall
{
    /// @dev Access control: aditional roles.
    bytes32 public constant LISTER_ROLE = keccak256("LISTER_ROLE");

    /// @dev Top level control center contract.
    ProtocolControl internal controlCenter;

    /// @dev Total number of listings on market.
    uint256 public totalListings;

    /// @dev Collection level metadata.
    string public _contractURI;

    /// @dev Whether listing is restricted by LISTER_ROLE.
    bool public restrictedListerRoleOnly;

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

    /// @dev The marketplace fee.
    uint64 public marketFeeBps;

    /// @dev The minimum amount of time left in an auction after a new bid is created. Default: 15 minutes.
    uint64 public timeBuffer = 15 minutes;

    /// @dev The minimum % increase required from the previous winning bid. Default: 5%.
    uint64 public bidBufferBps = 500;

    /// @dev listingId => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev listingId => address => info related to offers on a direct listing.
    mapping(uint => mapping(address => Offer)) public offers;

    /// @dev listingId => current highest bid
    mapping(uint => Offer) public winningBid;

    /// @dev listingId => buyer address => tokens bought
    mapping(uint256 => mapping(address => uint256)) public boughtFromListing;

    /// @dev Checks whether caller is a listing creator.
    modifier onlyListingCreator(uint256 _listingId) {
        require(
            listings[_listingId].tokenOwner == _msgSender(),
            "Market: caller is not listing creator."
        );
        _;
    }

    /// @dev Checks whether caller has LISTER_ROLE when `restrictedListerRoleOnly` is active.
    modifier onlyListerRoleWhenRestricted() {
        require(
            !restrictedListerRoleOnly || hasRole(LISTER_ROLE, _msgSender()),
            "Market: caller does not have LISTER_ROLE."
        );
        _;
    }

    /// @dev Checks whether the caller is a module admin.
    modifier onlyModuleAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 
            "Market: not a module admin."
        );
        _;
    }

    constructor(
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri,
        uint256 _marketFeeBps
    ) ERC2771Context(_trustedForwarder) {

        _contractURI = _uri; // Contract level metadata
        controlCenter = ProtocolControl(_controlCenter); // Top level control center contract.
        marketFeeBps = uint64(_marketFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LISTER_ROLE, _msgSender());
    }

    //  =====   External functions  =====

    /// @dev Lets a token owner list tokens for sale: Direct Listing or Auction.
    function createListing(
        ListingParameters memory _params
    ) 
        external
        override
        onlyListerRoleWhenRestricted 
    {
        // Get values to populate `Listing`.
        uint256 listingId = nextListingId();
        address tokenOwner = _msgSender();
        TokenType tokenTypeOfListing = getTokenType(_params.assetContract);

        require(
            _params.quantityToList > 0 
                && validateOwnershipAndApproval(
                    tokenOwner,
                    _params.assetContract, 
                    _params.tokenId, 
                    _params.quantityToList, 
                    tokenTypeOfListing, 
                    _params.listingType
                ), 
            "Market: must own and approve to transfer tokens."
        );

        Listing memory newListing = Listing({
            listingId: listingId,

            tokenOwner: tokenOwner,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,

            startTime: block.timestamp + _params.secondsUntilStartTime,
            endTime: _params.secondsUntilEndTime == 0 ? type(uint256).max : block.timestamp + _params.secondsUntilEndTime,
            
            quantity: getSafeQuantity(tokenTypeOfListing, _params.quantityToList),
            currency: _params.currencyToAccept,

            reservePricePerToken: _params.reservePricePerToken,
            buyoutPricePerToken: _params.buyoutPricePerToken,
            tokensPerBuyer: _params.tokensPerBuyer == 0 ? _params.quantityToList : _params.tokensPerBuyer,            
            
            tokenType: tokenTypeOfListing,
            listingType: _params.listingType
        });

        listings[listingId] = newListing;

        emit NewListing(_params.assetContract, tokenOwner, listingId, newListing);
    }

    /// @dev Lets a listing's creator edit the listing's parameters.
    function editListingParametrs(    
        uint256 _listingId,
        uint256 _quantityToList,
        uint256 _reservePricePerToken,    
        uint256 _buyoutPricePerToken,
        uint256 _tokensPerBuyer,
        address _currencyToAccept,
        uint256 _secondsUntilStartTime,
        uint256 _secondsUntilEndTime
    ) 
        external
        override
        onlyListingCreator(_listingId)
    {
        Listing memory targetListing = listings[_listingId];
        uint256 safeNewQuantity = getSafeQuantity(targetListing.tokenType, _quantityToList);

        /**
         * E.g. `_reservePricePerToken` is specific to auctions, whereas
         * e.g. `_tokensPerBuyer` is specific to direct listings.
         */        
        if(targetListing.listingType == ListingType.Auction) {
            require(
                targetListing.startTime < block.timestamp,
                "Market: cannot edit auction after start."
            );

            targetListing.reservePricePerToken = _reservePricePerToken;
            targetListing.buyoutPricePerToken = _buyoutPricePerToken;

        }

        if(targetListing.quantity != _quantityToList) {
            require(
                validateOwnershipAndApproval(
                    targetListing.tokenOwner, 
                    targetListing.assetContract, 
                    targetListing.tokenId, 
                    safeNewQuantity, 
                    targetListing.tokenType,
                    targetListing.listingType
                ), 
                "Market: must own and approve to transfer tokens."
            );
            targetListing.quantity = safeNewQuantity;
        }

        targetListing.currency = _currencyToAccept;
        targetListing.tokensPerBuyer = _tokensPerBuyer;
        targetListing.startTime = _secondsUntilStartTime == 0
            ? targetListing.startTime
            : block.timestamp + _secondsUntilStartTime;
        targetListing.endTime = _secondsUntilEndTime == 0
            ? targetListing.endTime
            : block.timestamp + _secondsUntilEndTime;

        listings[_listingId] = targetListing;

        emit ListingUpdate(targetListing.tokenOwner, _listingId, targetListing);
    }

    /// @dev Lets an account buy a given quantity of tokens from a listing.
    function buy(
        uint256 _listingId, 
        uint256 _quantityToBuy
    ) 
        external
        override
        nonReentrant
    {
        Listing memory targetListing = listings[_listingId];
        address buyer = _msgSender();

        validateDirectListingSale(targetListing, buyer, _quantityToBuy);

        targetListing.quantity -= _quantityToBuy;
        listings[_listingId] = targetListing;
        boughtFromListing[_listingId][buyer] += _quantityToBuy;

        // Distribute sale value to stakeholders
        if (targetListing.buyoutPricePerToken > 0) {
            payout(
                buyer, 
                targetListing.tokenOwner, 
                targetListing.buyoutPricePerToken * _quantityToBuy,
                targetListing
            );
        }

        // Transfer tokens being bought to buyer.
        sendTokens(targetListing.tokenOwner, buyer, _quantityToBuy, targetListing);

        emit NewDirectSale(
            targetListing.assetContract, 
            targetListing.tokenOwner, 
            targetListing.listingId, 
            buyer, 
            _quantityToBuy, 
            targetListing
        );
    }

    function offer(
        uint256 _listingId, 
        uint256 _quantityWanted, 
        uint256 _totalOfferAmount
    ) 
        external
        override
        nonReentrant
    {
        Listing memory targetListing = listings[_listingId];

        if(targetListing.listingType == ListingType.Auction) {
            require(
                targetListing.reservePricePerToken * targetListing.quantity <= _totalOfferAmount,
                "Market: must bid at least reserve price."
            );
            require(
                targetListing.endTime > block.timestamp && targetListing.startTime < block.timestamp,
                "Market: can only make bids in auction duration."
            );
        }

        address offeror = _msgSender();
        uint256 quantityWanted = targetListing.listingType == ListingType.Auction
            ? getSafeQuantity(targetListing.tokenType, targetListing.quantity)
            : getSafeQuantity(targetListing.tokenType, _quantityWanted);

        validateCurrencyBalAndApproval(
            offeror, 
            targetListing.currency, 
            _totalOfferAmount
        );

        Offer memory newOffer = Offer({
            listingId: _listingId,
            offeror: offeror,
            quantityWanted: quantityWanted,
            offerAmount: _totalOfferAmount
        });

        offers[_listingId][offeror] = newOffer;

        emit NewOffer(_listingId, offeror, newOffer, targetListing);

        if(targetListing.listingType == ListingType.Auction) {
            handleBid(targetListing, newOffer);
        }
    }

    /// @dev Lets a listing's creator accept an offer for their direct listing.
    function acceptOffer(
        uint256 _listingId, 
        address offeror
    ) 
        external
        override
        nonReentrant
        onlyListingCreator(_listingId)
    {
        Offer memory targetOffer = offers[_listingId][offeror];
        Listing memory targetListing = listings[_listingId];

        require(
            targetListing.listingType == ListingType.Direct
                && validateOwnershipAndApproval(
                    targetListing.tokenOwner, 
                    targetListing.assetContract, 
                    targetListing.tokenId, 
                    targetOffer.quantityWanted, 
                    targetListing.tokenType,
                    targetListing.listingType
                ), 
            "Market: must own and approve to transfer tokens."
        );

        targetListing.quantity -= targetOffer.quantityWanted;
        listings[_listingId] = targetListing;

        payout(
            offeror, 
            targetListing.tokenOwner, 
            targetOffer.offerAmount * targetOffer.quantityWanted, 
            targetListing
        );
        sendTokens(targetListing.tokenOwner, offeror, targetOffer.quantityWanted, targetListing);

        emit NewDirectSale(
            targetListing.assetContract, 
            targetListing.tokenOwner, 
            _listingId, 
            offeror, 
            targetOffer.quantityWanted,
            targetListing
        );
    }

    /// @dev Lets an auction's creator close the auction.
    function closeAuction(
        uint256 _listingId
    )
        external
        override
        nonReentrant
    {
        Listing memory targetListing = listings[_listingId];
        Offer memory targetBid = winningBid[_listingId];
        
        address closer = _msgSender();

        if(targetListing.startTime > block.timestamp) {

            require(
                listings[_listingId].tokenOwner == closer,
                "Market: caller does not the listing creator."
            );

            // Auction is considered canceled if end time has passed.
            uint256 quantityToSend = targetListing.quantity;
            targetListing.quantity = 0;
            targetListing.endTime = block.timestamp;
            listings[_listingId] = targetListing;

            sendTokens(address(this), targetListing.tokenOwner, quantityToSend, targetListing);

            emit AuctionCanceled(_listingId, targetListing.tokenOwner, targetListing);

            return;
        }

        require(
            closer == targetListing.tokenOwner || closer == targetBid.offeror,
            "Market: must be bidder or auction creator."
        );
        require(
            targetListing.listingType == ListingType.Auction,
            "Market: listing is not an auction."
        );
        require(
            targetListing.endTime < block.timestamp,
            "Market: can only close auction after it has ended."
        );

        if(_msgSender() == targetListing.tokenOwner) {
            /**
             * Prevent re-entrancy by setting bid's offer amount, and listing's quantity to 0 before ERC20 transfer.
             */
            uint256 payoutAmount = targetBid.offerAmount * targetListing.quantity;

            targetListing.quantity = 0;
            targetListing.endTime = block.timestamp;
            listings[_listingId] = targetListing;

            targetBid.offerAmount = 0;
            winningBid[_listingId] = targetBid;

            payout(
                address(this), 
                targetListing.tokenOwner, 
                payoutAmount,
                targetListing
            );
        } else if (_msgSender() == targetBid.offeror) {
            /**
             * Prevent re-entrancy by setting bid's quantity to 0 before token transfer.
             */
            
            uint256 quantityToSend = targetBid.quantityWanted;

            targetBid.quantityWanted = 0;
            winningBid[_listingId] = targetBid;

            sendTokens(address(this), targetBid.offeror, quantityToSend, targetListing);
        }
        

        emit AuctionClosed(_listingId, closer, targetListing.tokenOwner, targetBid.offeror, targetBid, targetListing);
    }

    //  =====   Internal functions  =====

    /// @dev Processes a bid on an existing auction.
    function handleBid(
        Listing memory _targetListing,
        Offer memory _incomingOffer 
    )
        internal
    {
        Offer memory currentWinningBid = winningBid[_targetListing.listingId];

        if(isNewHighestBid(currentWinningBid.offerAmount, _incomingOffer.offerAmount)) {

            address prevBidder = currentWinningBid.offeror;
            uint256 prevBidAmount = currentWinningBid.offerAmount;  

            currentWinningBid = _incomingOffer;
            
            // Collect incoming bid and payout previous highest bidder.
            handleIncomingBid(_targetListing.currency, _incomingOffer.offeror, _incomingOffer.offerAmount);
            IERC20(_targetListing.currency).transferFrom(address(this), prevBidder, prevBidAmount);

            // Close auction and execute sale if there's a buyout amount and incoming offer amount is buyout amount.
            if(
                _targetListing.buyoutPricePerToken > 0
                    && _incomingOffer.offerAmount >= _targetListing.buyoutPricePerToken * _targetListing.quantity
            ) {
                
                uint256 quantityToSend = currentWinningBid.quantityWanted;
                currentWinningBid.quantityWanted = 0;
                _targetListing.endTime = block.timestamp;

                sendTokens(address(this), currentWinningBid.offeror, quantityToSend, _targetListing);
            
            } else if(_targetListing.endTime - block.timestamp <= timeBuffer) {
                _targetListing.endTime += timeBuffer;
            }

            listings[_targetListing.listingId] = _targetListing;
            winningBid[_targetListing.listingId] = currentWinningBid;

            emit NewBid(_targetListing.listingId, _incomingOffer.offeror, currentWinningBid, _targetListing);
        }
    }

    /// @dev Sends the appropriate kind of token to caller.
    function sendTokens(address _from, address _to, uint256 _quantity, Listing memory _listing) internal {
        if (_listing.tokenType == TokenType.ERC1155) {
            IERC1155(_listing.assetContract).safeTransferFrom(
                _from,
                _to,
                _listing.tokenId,
                _quantity,
                ""
            );
        } else if (_listing.tokenType == TokenType.ERC721) {
            IERC721(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, "");
        }
    }

    /// @dev Payout stakeholders on sale
    function payout(
        address _payer,
        address _payee,
        uint256 _totalPayoutAmount,
        Listing memory _listing
    ) 
        internal 
    {

        bool transferSuccess;

        // Collect protocol fee
        uint256 marketCut = (_totalPayoutAmount * marketFeeBps) / MAX_BPS;

        transferSuccess = IERC20(_listing.currency).transferFrom(
            _payer,
            controlCenter.getRoyaltyTreasury(address(this)),
            marketCut
        );

        uint256 remainder = _totalPayoutAmount - marketCut;

        // Distribute royalties
        if (IERC165(_listing.assetContract).supportsInterface(type(IERC2981).interfaceId)) {
            (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(_listing.assetContract).royaltyInfo(
                _listing.tokenId,
                _totalPayoutAmount
            );

            if (royaltyReceiver != address(0) && royaltyAmount > 0) {
                require(royaltyAmount + marketCut <= _totalPayoutAmount, "Market: Total market fees exceed the price.");

                remainder -= royaltyAmount;

                transferSuccess = IERC20(_listing.currency).transferFrom(_payer, royaltyReceiver, royaltyAmount);
            }
        }

        // Distribute price to token owner
        transferSuccess = IERC20(_listing.currency).transferFrom(_payer, _payee, remainder);

        require(transferSuccess, "Market: failed to payout stakeholders.");
    }

    /// @dev See https://github.com/ourzora/auction-house/blob/main/contracts/AuctionHouse.sol#L331-L338
    function handleIncomingBid(
        address _currency,
        address _from, 
        uint256 _amount
    )
        internal
    {
        address to = address(this);

        uint256 balBefore = IERC20(_currency).balanceOf(to);
        bool success = IERC20(_currency).transferFrom(_from, to, _amount);
        uint256 balAfter = IERC20(_currency).balanceOf(to);

        require(
            success && balAfter == balBefore + _amount,
            "Market: failed to receive incoming bid."
        );
    }

    /// @dev Checks whether an incoming bid should be the new current highest bid.
    function isNewHighestBid(
        uint256 _currentBid,
        uint256 _incomingBid
    )
        internal
        view
        returns (bool isValidNewBid)
    {
        isValidNewBid = _incomingBid >  _currentBid
            && ((_incomingBid - _currentBid) * MAX_BPS) / _currentBid >= bidBufferBps;
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Market to transfer tokens.
    function validateOwnershipAndApproval(
        address _tokenOwner, 
        address _assetContract, 
        uint256 _tokenId, 
        uint256 _quantity, 
        TokenType _tokenType,
        ListingType _listingType
    ) 
        internal
        returns (bool isValid) 
    {
        address market = address(this);

        if(_tokenType == TokenType.ERC1155) {
            isValid = IERC1155(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity
                && IERC1155(_assetContract).isApprovedForAll(_tokenOwner, market);

            if(isValid && _listingType == ListingType.Auction) {
                IERC1155(_assetContract).safeTransferFrom(_tokenOwner, market, _tokenId, _quantity, "");
            }
        } else if (_tokenType == TokenType.ERC721) {
            isValid = IERC721(_assetContract).ownerOf(_tokenId) == _tokenOwner
                && (
                    IERC721(_assetContract).getApproved(_tokenId) == market
                        || IERC721(_assetContract).isApprovedForAll(_tokenOwner, market)
                );
            if(isValid && _listingType == ListingType.Auction) {
                IERC721(_assetContract).safeTransferFrom(_tokenOwner, market, _tokenId, "");
            }
        }
    }

    /// @dev Validates caller's token balance and approval for Market to transfer tokens.
    function validateCurrencyBalAndApproval(
        address _caller, 
        address _currency,
        uint256 _balanceToCheck
    )
        internal
        view
    {
        require(
            IERC20(_currency).balanceOf(_caller) >= _balanceToCheck
                && IERC20(_currency).allowance(_caller, address(this)) >= _balanceToCheck,
            "Market: must own and approve Market to transfer currency."
        );
    }

    /// @dev Validates conditions of a direct listing sale.
    function validateDirectListingSale(
        Listing memory _listing, 
        address _buyer,
        uint256 _quantityToBuy
    )
        internal
    {
        validateCurrencyBalAndApproval(
            _buyer, 
            _listing.currency, 
            _quantityToBuy * _listing.buyoutPricePerToken
        );

        // Fails if listing is an auction, since creating an auction requires
        // escrowing tokens in the Market.
        require(
            validateOwnershipAndApproval(
                _listing.tokenOwner, 
                _listing.assetContract, 
                _listing.tokenId, 
                _listing.quantity, 
                _listing.tokenType,
                _listing.listingType
            ),
            "Market: cannot buy tokens from this listing."
        );
        
        require(
            _quantityToBuy > 0 
                && _quantityToBuy <= _listing.quantity
                && _quantityToBuy + boughtFromListing[_listing.listingId][_buyer] <= _listing.tokensPerBuyer,
            "Market: must buy an appropriate amount of tokens."
        );
        require(
            block.timestamp <= _listing.endTime && block.timestamp >= _listing.startTime,
            "Market: the sale has either not started or closed."
        );
    }

    /// @dev Enforces quantity == 1 if tokenType is TokenType.ERC721.
    function getSafeQuantity(
        TokenType _tokenType, 
        uint256 _quantityToCheck
    ) 
        internal
        pure
        returns (uint256 safeQuantity) 
    {   
        if(_quantityToCheck == 0) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721 ? 1 : _quantityToCheck;
        }
    }

    /// @dev Checks the interface supported by a contract.
    function getTokenType(
        address _assetContract
    ) 
        internal
        view
        returns (TokenType tokenType) 
    {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {            
            tokenType = TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("Market: must implement ERC 1155 or ERC 721.");
        }
    }

    /// @dev Returns the next listing Id to use.
    function nextListingId() internal returns (uint256 nextId) {
        nextId = totalListings;
        totalListings += 1;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    //  ===== Setter functions  =====

    /// @dev Lets a protocol admin set market fees.
    function setMarketFeeBps(uint256 _feeBps) external onlyModuleAdmin {

        require(_feeBps < MAX_BPS, "Market: invalid BPS.");

        /**
         *  Gas optimization -- take a uint256 argument.
         */
        marketFeeBps = uint64(_feeBps);
        emit MarketFeeUpdate(uint64(_feeBps));
    }

    /// @dev Lets a module admin set auction buffers
    function setAuctionBuffers(uint256 _timeBuffer, uint256 _bidBufferBps) external onlyModuleAdmin {
        
        require(_bidBufferBps < MAX_BPS, "Market: invalid BPS.");
        
        timeBuffer = uint64(_timeBuffer);
        bidBufferBps = uint64(_bidBufferBps);

        emit AuctionBuffersUpdated(_timeBuffer, _bidBufferBps);
    }

    /// @dev Lets a module admin restrict listing by LISTER_ROLE.
    function setRestrictedListerRoleOnly(bool restricted) external onlyModuleAdmin {
        restrictedListerRoleOnly = restricted;
        emit RestrictedListerRoleUpdated(restricted);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _uri) external {
        require(
            controlCenter.hasRole(controlCenter.DEFAULT_ADMIN_ROLE(), _msgSender()),
            "Market: only a protocol admin can call this function."
        );

        _contractURI = _uri;
    }

    //  ===== Getter functions  =====

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     *   ERC 1155 and ERC 721 Receiver functions.
     **/

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
        override(AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC1155Receiver).interfaceId 
            || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC2981).interfaceId;
    }
}