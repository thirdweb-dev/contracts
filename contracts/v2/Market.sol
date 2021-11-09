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
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Market is
    IMarket,
    AccessControlEnumerable,
    Pausable,
    IERC1155Receiver,
    IERC721Receiver,
    ReentrancyGuard,
    ERC2771Context,
    Multicall
{
    /// @dev Access control: aditional roles.
    bytes32 public constant LISTER_ROLE = keccak256("LISTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev Total number of listings on market.
    uint256 public totalListings;

    /// @dev Collection level metadata.
    string public _contractURI;

    /// @dev The marketplace fee.
    uint128 public marketFeeBps;

    /// @dev ADD COMMENT LATER
    bool public restrictedListerRoleOnly;

    /// @dev listingId => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev listingId => address => info related to offers on a direct listing.
    mapping(uint => mapping(address => Offer)) public offers;

    /// @dev listingId => buyer address => tokens bought
    mapping(uint256 => mapping(address => uint256)) public boughtFromListing;

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

    /// @dev Checks whether caller is a listing creator.
    modifier onlyLister(uint256 _listingId) {
        require(
            listings[_listingId].tokenOwner == _msgSender(),
            "Market: caller does not the listing creator."
        );

        _;
    }

    /// @dev Checks whether a listing with ID `_listingId` exists.
    modifier onlyExistingListing(uint256 _listingId) {
        require(_listingId <= totalListings, "Market: listing does not exist.");
        _;
    }

    constructor(
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri
    ) ERC2771Context(_trustedForwarder) {
        // Set contract URI
        _contractURI = _uri;

        // Set the protocol control center.
        controlCenter = ProtocolControl(_controlCenter);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LISTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    //  =====   External functions  =====

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
    ) 
        external
        whenNotPaused 
    {

        uint256 listingId = nextListingId();
        address tokenOwner = _msgSender();
        TokenType tokenTypeOfListing = getTokenType(_assetContract);

        bool isValid;

        if(listingType == ListingType.Direct) {
            isValid = validateOwnershipAndApproval(tokenOwner, _assetContract, _tokenId, _quantityToList, tokenTypeOfListing);
        } else if(listingType == ListingType.Auction) {
            isValid = takeTokensOnList(tokenOwner, _assetContract, _tokenId, _quantityToList, tokenTypeOfListing);
        }

        require(isValid && _quantityToList > 0, "Market: must own and approve to transfer tokens.");

        Listing memory newListing = Listing({
            listingId: listingId,

            tokenOwner: tokenOwner,
            assetContract: _assetContract,
            tokenId: _tokenId,

            startTime: block.timestamp + _secondsUntilStartTime,
            endTime: _secondsUntilEndTime == 0 ? type(uint256).max : block.timestamp + _secondsUntilEndTime,
            
            quantity: getSafeQuantity(tokenTypeOfListing, _quantityToList),
            currency: _currencyToAccept,

            reservePricePerToken: _reservePricePerToken,
            buyoutPricePerToken: _buyoutPricePerToken,
            tokensPerBuyer: _tokensPerBuyer == 0 ? _quantityToList : _tokensPerBuyer,

            currentHighestBid: 0,
            bidder: address(0),
            
            tokenType: tokenTypeOfListing,
            listingType: listingType
        });

        listings[listingId] = newListing;

        emit NewListing(_assetContract, _msgSender(), listingId, newListing);
    }

    /// @dev Lets a listing's creator edit the quantity of tokens listed.
    function editListingQuantity(
        uint256 _listingId, 
        uint256 _newQuantity
    ) 
        external
        whenNotPaused 
        onlyExistingListing(_listingId)
        onlyLister(_listingId) 
    {
        Listing memory targetListing = listings[_listingId];

        bool isValid = validateOwnershipAndApproval(
            targetListing.tokenOwner, 
            targetListing.assetContract, 
            targetListing.tokenId, 
            _newQuantity, 
            targetListing.tokenType
        );

        require(isValid, "Market: must own and approve to transfer tokens.");
        targetListing.quantity = getSafeQuantity(targetListing.tokenType, _newQuantity);
        listings[_listingId] = targetListing;

        emit ListingUpdate(targetListing.tokenOwner, _listingId, targetListing);
    }

    /// @dev Lets a listing's creator edit the listing's parameters.
    function editListingParametrs(    
        uint256 _listingId,
        uint256 _reservePricePerToken,    
        uint256 _buyoutPricePerToken,
        uint256 _tokensPerBuyer,
        address _currencyToAccept,
        uint256 _secondsUntilStartTime,
        uint256 _secondsUntilEndTime
    ) 
        external
        whenNotPaused
        onlyExistingListing(_listingId)
        onlyLister(_listingId)
    {
        Listing memory targetListing = listings[_listingId];

        targetListing.currency = _currencyToAccept;
        targetListing.startTime = _secondsUntilStartTime == 0
            ? targetListing.startTime
            : block.timestamp + _secondsUntilStartTime;
        targetListing.endTime = _secondsUntilEndTime == 0
            ? targetListing.endTime
            : block.timestamp + _secondsUntilEndTime;
        
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

        } else if (targetListing.listingType == ListingType.Direct) {
            targetListing.tokensPerBuyer = _tokensPerBuyer;
        }

        listings[_listingId] = targetListing;

        emit ListingUpdate(targetListing.tokenOwner, _listingId, targetListing);
    }

    /// @dev Lets an account buy a given quantity of tokens from a listing.
    function buy(
        uint256 _listingId, 
        uint256 _quantityToBuy
    ) 
        external
        whenNotPaused
        onlyExistingListing(_listingId)
        nonReentrant
    {
        Listing memory targetListing = listings[_listingId];
        address buyer = _msgSender();

        validateDirectListingSale(targetListing, buyer, _quantityToBuy);

        boughtFromListing[_listingId][buyer] += _quantityToBuy;
        targetListing.quantity -= _quantityToBuy;
        listings[_listingId] = targetListing;

        // Distribute sale value to stakeholders
        if (targetListing.buyoutPricePerToken > 0) {
            payoutOnDirectSale(targetListing, _quantityToBuy);
        }

        // Transfer tokens being bought to buyer.
        sendTokens(targetListing, _quantityToBuy);

        emit NewDirectSale(
            targetListing.assetContract, 
            targetListing.tokenOwner, 
            targetListing.listingId, 
            buyer, 
            _quantityToBuy, 
            targetListing
        );
    }

    //  =====   Internal functions  =====

    /// @dev Transfers the token being listed to the Market.
    function takeTokensOnList(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal returns (bool success) {

        address market = address(this);
        success = validateOwnershipAndApproval(
            _tokenOwner, 
            _assetContract, 
            _tokenId, 
            _quantity, 
            _tokenType
        );

        if(success) {
            if (_tokenType == TokenType.ERC1155) {            
                IERC1155(_assetContract).safeTransferFrom(_tokenOwner, market, _tokenId, _quantity, "");
            } else if (_tokenType == TokenType.ERC721) {
                IERC721(_assetContract).safeTransferFrom(_tokenOwner, market, _tokenId, "");
            }
        }
    }

    /// @dev Sends the appropriate kind of token to caller.
    function sendTokens(Listing memory _listing, uint256 _quantity) internal {
        if (_listing.tokenType == TokenType.ERC1155) {
            IERC1155(_listing.assetContract).safeTransferFrom(
                _listing.tokenOwner,
                _msgSender(),
                _listing.tokenId,
                _quantity,
                ""
            );
        } else if (_listing.tokenType == TokenType.ERC721) {
            IERC721(_listing.assetContract).safeTransferFrom(_listing.tokenOwner, _msgSender(), _listing.tokenId, "");
        }
    }

    /// @dev Payout stakeholders on sale
    function payoutOnDirectSale(Listing memory _listing, uint256 _quantityBought) internal {
        
        uint256 totalPrice = _listing.buyoutPricePerToken * _quantityBought;

        require(
            IERC20(_listing.currency).allowance(_msgSender(), address(this)) >= totalPrice,
            "Market: must approve Market to transfer price to pay."
        );

        // Collect protocol fee
        uint256 marketCut = (totalPrice * marketFeeBps) / controlCenter.MAX_BPS();

        require(
            IERC20(_listing.currency).transferFrom(
                _msgSender(),
                controlCenter.getRoyaltyTreasury(address(this)),
                marketCut
            ),
            "Market: failed to transfer protocol cut."
        );

        uint256 sellerCut = totalPrice - marketCut;

        // Distribute royalties
        if (IERC165(_listing.assetContract).supportsInterface(type(IERC2981).interfaceId)) {
            (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(_listing.assetContract).royaltyInfo(
                _listing.tokenId,
                totalPrice
            );

            if (royaltyReceiver != address(0) && royaltyAmount > 0) {
                require(royaltyAmount + marketCut <= totalPrice, "Market: Total market fees exceed the price.");

                sellerCut = sellerCut - royaltyAmount;

                require(
                    IERC20(_listing.currency).transferFrom(_msgSender(), royaltyReceiver, royaltyAmount),
                    "Market: failed to transfer creator cut."
                );
            }
        }

        // Distribute price to seller
        require(
            IERC20(_listing.currency).transferFrom(_msgSender(), _listing.tokenOwner, sellerCut),
            "Market: failed to transfer seller cut."
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
        internal 
        returns (bool isValid) 
    {

        address operator = address(this);

        if(_tokenType == TokenType.ERC1155) {
            isValid = IERC1155(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity
                && IERC1155(_assetContract).isApprovedForAll(_tokenOwner, operator);
        } else if (_tokenType == TokenType.ERC721) {
            isValid = IERC721(_assetContract).ownerOf(_tokenId) == _tokenOwner
                && (
                    IERC721(_assetContract).getApproved(_tokenId) == operator
                        || IERC721(_assetContract).isApprovedForAll(_tokenOwner, operator)
                );
        }
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
            "Market: can only buy from direct listings."
        );
        require(
            _quantityToBuy > 0 && _quantityToBuy <= _listing.quantity, 
            "Market: must buy an appropriate amount of tokens."
        );
        require(
            block.timestamp <= _listing.endTime && block.timestamp >= _listing.startTime,
            "Market: the sale has either not started or closed."
        );
        require(
            _quantityToBuy + boughtFromListing[_listing.listingId][_buyer] <= _listing.tokensPerBuyer,
            "Market: Cannot buy more from listing than permitted."
        );
        require(
            validateOwnershipAndApproval(
                _listing.tokenOwner, 
                _listing.assetContract, 
                _listing.tokenId, 
                _listing.quantity, 
                _listing.tokenType
            ),
            "Market: must own and approve to transfer tokens."
        );
    }

    function getSafeQuantity(
        TokenType _tokenType, 
        uint256 _quantityToSet
    ) 
        internal 
        returns (uint256 safeQuantity) 
    {   
        if(_quantityToSet == 0) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721 ? 1 : _quantityToSet;
        }
    }

    function getTokenType(address _assetContract) internal returns (TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {            
            tokenType = TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {

            tokenType = TokenType.ERC721;
        } else {
            revert("Market: token must implement either ERC 1155 or ERC 721.");
        }
    }

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
}