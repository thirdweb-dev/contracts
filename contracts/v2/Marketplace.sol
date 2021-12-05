// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { IMarketplace } from "./IMarketplace.sol";
import { IWETH } from "../interfaces/IWETH.sol";

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

contract Marketplace is
    IMarketplace,
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

    /// @dev The address interpreted as native token of the chain.
    address public constant nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The address of the native token wrapper contract.
    address public immutable nativeTokenWrapper;

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
        address _nativeTokenWrapper,
        string memory _uri,
        uint256 _marketFeeBps
    ) ERC2771Context(_trustedForwarder) {

        _contractURI = _uri; // Contract level metadata
        controlCenter = ProtocolControl(_controlCenter); // Top level control center contract.
        nativeTokenWrapper = _nativeTokenWrapper;
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
        uint256 tokenAmountToList = getSafeQuantity(tokenTypeOfListing, _params.quantityToList);

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

            startTime: _params.startTime < block.timestamp ? block.timestamp : _params.startTime,
            endTime: _params.secondsUntilEndTime == 0 ? type(uint256).max : _params.startTime + _params.secondsUntilEndTime,
            
            quantity: tokenAmountToList,
            currency: _params.currencyToAccept,

            reservePricePerToken: _params.reservePricePerToken,
            buyoutPricePerToken: _params.buyoutPricePerToken,  
            
            tokenType: tokenTypeOfListing,
            listingType: _params.listingType
        });

        listings[listingId] = newListing;

        if(newListing.listingType == ListingType.Auction) {
            transferListingTokens(tokenOwner, address(this), tokenAmountToList, newListing);
        }

        emit NewListing(listingId, _params.assetContract, tokenOwner, newListing);
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
    )
        external
        override
        onlyListingCreator(_listingId)
    {
        Listing memory targetListing = listings[_listingId];
        uint256 safeNewQuantity = getSafeQuantity(targetListing.tokenType, _quantityToList);
        bool isAuction = targetListing.listingType == ListingType.Auction;

        // Can only edit auction listing before it starts.
        if(isAuction) {
            require(
                block.timestamp < targetListing.startTime,
                "Market: auction already started."
            );
        }

        listings[_listingId] = Listing({
            listingId: _listingId,

            tokenOwner: _msgSender(),
            assetContract: targetListing.assetContract,
            tokenId: targetListing.tokenId,

            startTime: _startTime == 0 ? targetListing.startTime : _startTime,
            endTime: _secondsUntilEndTime == 0 ? targetListing.endTime : targetListing.startTime + _secondsUntilEndTime,

            quantity: safeNewQuantity,
            currency: _currencyToAccept,

            reservePricePerToken: _reservePricePerToken,
            buyoutPricePerToken: _buyoutPricePerToken,
            
            tokenType: targetListing.tokenType,
            listingType: targetListing.listingType
        });

        // Must validate ownership and approval of the new quantity of tokens for diret listing.
        if(targetListing.quantity != safeNewQuantity) {

            if(isAuction) {
                transferListingTokens(address(this), targetListing.tokenOwner, targetListing.quantity, targetListing);
            }
            
            validateOwnershipAndApproval(
                targetListing.tokenOwner,
                targetListing.assetContract, 
                targetListing.tokenId, 
                safeNewQuantity, 
                targetListing.tokenType
            );

            if(isAuction) {
                transferListingTokens(targetListing.tokenOwner, address(this), safeNewQuantity, targetListing);
            }
        }

        emit ListingUpdate(_listingId, targetListing.tokenOwner);
    }

    /// @dev Lets an account buy a given quantity of tokens from a listing.
    function buy(
        uint256 _listingId, 
        uint256 _quantityToBuy
    )
        external
        payable
        override
        nonReentrant
    {
        Listing memory targetListing = listings[_listingId];
        address buyer = _msgSender();

        executeSale(
            targetListing, 
            buyer, 
            targetListing.currency,
            targetListing.buyoutPricePerToken * _quantityToBuy, 
            _quantityToBuy
        );
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
        
        delete offers[_listingId][offeror];

        executeSale(
            targetListing,
            offeror,
            targetOffer.currency, 
            targetOffer.pricePerToken * targetOffer.quantityWanted, 
            targetOffer.quantityWanted
        );
    }

    function offer(
        uint256 _listingId, 
        uint256 _quantityWanted,
        address _currency,
        uint256 _pricePerToken
    ) 
        external
        payable
        override
        nonReentrant
    {
        Listing memory targetListing = listings[_listingId];

        require(
            targetListing.endTime > block.timestamp && targetListing.startTime < block.timestamp,
            "Market: inactive lisitng."
        );
        
        // Both - (1) offers to direct listings, and (2) bids to auctions - share the same structure.
        Offer memory newOffer = Offer({
            listingId: _listingId,
            offeror: _msgSender(),
            quantityWanted: _quantityWanted,
            currency: _currency,
            pricePerToken: _pricePerToken
        });

        if (targetListing.listingType == ListingType.Auction) {
            
            // A bid to an auction must be made in the auction's desired currency.
            newOffer.currency = targetListing.currency;
            // A bid must be made for all auction items.
            newOffer.quantityWanted = getSafeQuantity(targetListing.tokenType, targetListing.quantity);

            handleBid(targetListing, newOffer);
            
        } else if (targetListing.listingType == ListingType.Direct) {
            
            // Offers to direct listings cannot be made directly in native tokens.
            newOffer.currency = _currency == nativeToken ? nativeTokenWrapper : _currency;
            newOffer.quantityWanted = getSafeQuantity(targetListing.tokenType, _quantityWanted);
            
            handleOffer(targetListing, newOffer);
        }
    }

    function executeSale(
        Listing memory _targetListing,
        address _buyer,
        address _currency,
        uint256 _currencyAmountToTransfer,
        uint256 _listingTokenAmountToTransfer
    ) internal {

        validateDirectListingSale(_targetListing, _buyer, _listingTokenAmountToTransfer);

        _targetListing.quantity -= _listingTokenAmountToTransfer;
        listings[_targetListing.listingId] = _targetListing;

        payout(
            _buyer, 
            _targetListing.tokenOwner,
            _currency,
            _currencyAmountToTransfer, 
            _targetListing
        );
        transferListingTokens(
            _targetListing.tokenOwner,
            _buyer,
            _listingTokenAmountToTransfer,
            _targetListing
        );

        emit NewSale(
            _targetListing.listingId,
            _targetListing.assetContract,
            _targetListing.tokenOwner,
            _buyer,
            _listingTokenAmountToTransfer,
            _currencyAmountToTransfer
        );
    }

    /// @dev Lets an auction's creator close the auction.
    function closeAuction(
        uint256 _listingId,
        address _closeFor
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
                "Market: caller is not the listing creator."
            );

            // Auction is considered canceled if end time has passed.
            uint256 quantityToSend = targetListing.quantity;
            targetListing.quantity = 0;
            targetListing.endTime = block.timestamp;
            listings[_listingId] = targetListing;

            transferListingTokens(address(this), targetListing.tokenOwner, quantityToSend, targetListing);

            emit AuctionClosed(
                _listingId,
                closer, 
                true,
                targetListing.tokenOwner,
                address(0)
            );

            return;
        }

        require(
            targetListing.listingType == ListingType.Auction,
            "Market: listing is not an auction."
        );
        require(
            targetListing.endTime < block.timestamp,
            "Market: can only close auction after it has ended."
        );

        if(_closeFor == targetListing.tokenOwner) {
            /**
             * Prevent re-entrancy by setting bid's offer amount, and listing's quantity to 0 before ERC20 transfer.
             */
            uint256 payoutAmount = targetBid.pricePerToken * targetBid.quantityWanted;

            targetListing.quantity = 0;
            targetListing.endTime = block.timestamp;
            listings[_listingId] = targetListing;

            targetBid.pricePerToken = 0;
            winningBid[_listingId] = targetBid;

            payout(
                address(this), 
                targetListing.tokenOwner,
                targetListing.currency,
                payoutAmount,
                targetListing
            );

            emit AuctionClosed(_listingId, closer, false, targetListing.tokenOwner, targetBid.offeror);

        } else if (_closeFor == targetBid.offeror) {
            _closeAuctionForBidder(targetListing, targetBid);
        }
    }

    /// @dev Let the contract accept ether
    receive() external payable {
        emit NativeTokensReceived(_msgSender(), msg.value);
    }

    //  =====   Internal functions  =====

    function handleOffer(
        Listing memory _targetListing,
        Offer memory _newOffer
    ) internal {
        require(
            _newOffer.quantityWanted <= _targetListing.quantity && _targetListing.quantity > 0,
            "Marketplace: insufficient tokens in listing."
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
            _newOffer.pricePerToken * _newOffer.quantityWanted
        );
    }

    function validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20(_currency).balanceOf(_addrToCheck) >= _currencyAmountToCheckAgainst
                && IERC20(_currency).allowance(_addrToCheck, address(this)) >= _currencyAmountToCheckAgainst,
            "Marketplace: insufficient currency balance or allowance."
        );
    }

    /// @dev Processes a bid on an existing auction.
    function handleBid(
        Listing memory _targetListing,
        Offer memory _incomingBid 
    )
        internal
    {

        Offer memory currentWinningBid = winningBid[_targetListing.listingId];
        uint256 currentOfferAmount = currentWinningBid.pricePerToken * currentWinningBid.quantityWanted;
        uint256 incomingOfferAmount = _incomingBid.pricePerToken * _incomingBid.quantityWanted;

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
            "Marketplace: not winning bid."
        );

        // Close auction and execute sale if there's a buyout amount and incoming offer amount is buyout amount.
        if(
            _targetListing.buyoutPricePerToken > 0
                && incomingOfferAmount >= _targetListing.buyoutPricePerToken * _targetListing.quantity
        ) {
            _closeAuctionForBidder(_targetListing, _incomingBid);
            transferListingTokens(address(this), _incomingBid.offeror, _incomingBid.quantityWanted, _targetListing);

        } else {
            
            // Update the winning bid and listing's end time before external contract calls.
            winningBid[_targetListing.listingId] = _incomingBid;

            if(_targetListing.endTime - block.timestamp <= timeBuffer) {
                _targetListing.endTime += timeBuffer;
                listings[_targetListing.listingId] = _targetListing;
            }

            // Payout previous highest bid.
            if(currentWinningBid.offeror != address(0) && currentOfferAmount > 0) {                
                transferCurrency(_targetListing.currency, address(this), currentWinningBid.offeror, currentOfferAmount);
            }

            // Collect incoming bid
            transferCurrency(_targetListing.currency, _incomingBid.offeror, address(this), incomingOfferAmount);
                
            emit NewOffer(_targetListing.listingId, _incomingBid.offeror, _targetListing.listingType, _incomingBid.quantityWanted, _targetListing.buyoutPricePerToken * _targetListing.quantity);
        }
    }

    function _closeAuctionForBidder(Listing memory _targetListing, Offer memory _winningBid) internal {
        _targetListing.endTime = block.timestamp;
        _winningBid.quantityWanted = 0;

        winningBid[_targetListing.listingId] = _winningBid;
        listings[_targetListing.listingId] = _targetListing;

        emit AuctionClosed(
            _targetListing.listingId,
            _msgSender(),
            false, 
            _winningBid.offeror,
            _targetListing.tokenOwner
        );
    }

    /// @dev Transfers tokens listed for sale in a direct or auction listing.
    function transferListingTokens(address _from, address _to, uint256 _quantity, Listing memory _listing) internal {
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

    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    )
        internal
    {
        if(_currency == nativeToken) {

            if(_from == address(this)) {
                IWETH(nativeTokenWrapper).withdraw(_amount);

                if(!safeTransferNativeToken(_to, _amount)) {
                    IWETH(nativeTokenWrapper).deposit{value: _amount}();
                    safeTransferERC20(_currency, address(this), _to, _amount);
                }
            } else if (_to == address(this)) {
                require(_amount == msg.value, "Market: native token value does not match bid amount.");
                IWETH(nativeTokenWrapper).deposit{value: _amount}();
            } else {
                if(!safeTransferNativeToken(_to, _amount)) {
                    IWETH(nativeTokenWrapper).deposit{value: _amount}();
                    safeTransferERC20(_currency, address(this), _to, _amount);
                }
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    )
        internal
    {
        if(_from == address(this)) {
            IERC20(_currency).approve(address(this), _amount);
        }

        uint256 balBefore = IERC20(_currency).balanceOf(_to);
        bool success = IERC20(_currency).transferFrom(_from, _to, _amount);
        uint256 balAfter = IERC20(_currency).balanceOf(_to);

        require(success && balAfter == balBefore + _amount, "Market: failed to transfer currency.");
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    /// @dev Payout stakeholders on sale
    function payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Listing memory _listing
    ) 
        internal 
    {
        // Collect protocol fee
        uint256 marketCut = (_totalPayoutAmount * marketFeeBps) / MAX_BPS;

        transferCurrency(_currencyToUse, _payer, controlCenter.getRoyaltyTreasury(address(this)), marketCut);

        uint256 remainder = _totalPayoutAmount - marketCut;

        // Distribute royalties. See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
        try IERC2981(_listing.assetContract).royaltyInfo(_listing.tokenId, _totalPayoutAmount) returns (
            address royaltyFeeRecipient,
            uint256 royaltyFeeAmount
        ) {
            if (royaltyFeeAmount > 0) {
                require(royaltyFeeAmount + marketCut <= _totalPayoutAmount, "Market: Total market fees exceed the price.");
                remainder -= royaltyFeeAmount;
                transferCurrency(_currencyToUse, _payer, royaltyFeeRecipient, royaltyFeeAmount);
            }
        } catch {}

        // Distribute price to token owner
        transferCurrency(_currencyToUse, _payer, _payee, remainder);
    }

    /// @dev Checks whether an incoming bid should be the new current highest bid.
    function isNewWinningBid(
        uint256 _reserveAmount,
        uint256 _currentWinningBidAmount,
        uint256 _incomingBidAmount)
        internal
        view
        returns (bool isValidNewBid)
    {
        isValidNewBid = (_currentWinningBidAmount == 0 && _incomingBidAmount >= _reserveAmount) 
            || (
                    _incomingBidAmount >  _currentWinningBidAmount
                        && ((_incomingBidAmount - _currentWinningBidAmount) * MAX_BPS) / _currentWinningBidAmount >= bidBufferBps
                );
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Market to transfer tokens.
    function validateOwnershipAndApproval(
        address _tokenOwner, 
        address _assetContract, 
        uint256 _tokenId, 
        uint256 _quantity, 
        TokenType _tokenType
    ) 
        internal view
    {
        address market = address(this);
        bool isValid;

        if(_tokenType == TokenType.ERC1155) {
            isValid = IERC1155(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity
                && IERC1155(_assetContract).isApprovedForAll(_tokenOwner, market);            
        } else if (_tokenType == TokenType.ERC721) {
            isValid = IERC721(_assetContract).ownerOf(_tokenId) == _tokenOwner
                && (
                    IERC721(_assetContract).getApproved(_tokenId) == market
                        || IERC721(_assetContract).isApprovedForAll(_tokenOwner, market)
                );
        }

        // Check `_quantity > 0` to ensure `_tokenOwner` has a non-zero balance of the concerned tokens.
        require(isValid && _quantity > 0, "Marketplace: insufficient NFT balance or approval.");
    }

    /// @dev Validates conditions of a direct listing sale.
    function validateDirectListingSale(
        Listing memory _listing, 
        address _buyer,
        uint256 _quantityToBuy
    )
        internal
    {

        require(
            _listing.listingType == ListingType.Direct,
            "Marketplace: cannot buy from listing."
        );

        // Check whether a valid quantity of listed tokens is being bought.
        require(
            _listing.quantity > 0 && _quantityToBuy <= _listing.quantity,
            "Market: buying invalid amount of tokens."
        );

        // Check if sale is made within the listing window.
        require(
            block.timestamp <= _listing.endTime && block.timestamp >= _listing.startTime,
            "Market: the sale has either not started or closed."
        );

        // Check: buyer owns and has approved sufficient currency for sale.
        if(_listing.currency == nativeToken) {
            require(
                msg.value == _quantityToBuy * _listing.buyoutPricePerToken,
                "Marketplace: insufficient currency balance or allowance." 
            );
        } else {

            validateERC20BalAndAllowance(
                _buyer,
                _listing.currency,
                _quantityToBuy * _listing.buyoutPricePerToken
            );
        }

        // Check if lisitng is a direct listing, and whether token owner owns and has approved
        // `quantityToBuy` amount of listing tokens from the listing.
        validateOwnershipAndApproval(
            _listing.tokenOwner, 
            _listing.assetContract, 
            _listing.tokenId, 
            _quantityToBuy, 
            _listing.tokenType
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
        emit ListingRestricted(restricted);
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