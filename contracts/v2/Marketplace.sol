// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { IMarketplace } from "./IMarketplace.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

contract Marketplace is
    IMarketplace,
    AccessControlEnumerable,
    Pausable,
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

    /// @dev Whether listing is restricted by LISTER_ROLE.
    bool public restrictedListerRoleOnly;

    /// @dev listingId => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev listingId => address => info related to offers on a direct listing.
    mapping(uint => mapping(address => Offer)) public offers;

    /// @dev listingId => buyer address => tokens bought
    mapping(uint256 => mapping(address => uint256)) public boughtFromListing;

    /// @dev Checks whether caller is a listing creator.
    modifier onlyListingCreator(uint256 _listingId) {
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

    /// @dev Checks whether caller has LISTER_ROLE when `restrictedListerRoleOnly` is active.
    modifier onlyListerRoleWhenRestricted() {
        require(
            !restrictedListerRoleOnly || hasRole(LISTER_ROLE, _msgSender()),
            "Market: only a lister can call this function."
        );
        _;
    }

    /// @dev Checks whether caller has PAUSER_ROLE.
    modifier onlyPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Market: must have pauser role."
        );
        _;
    }

    /// @dev Checks whether the caller is a protocol admin.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.DEFAULT_ADMIN_ROLE(), _msgSender()),
            "Market: only a protocol admin can call this function."
        );
        _;
    }

    /// @dev Checks whether the caller is a module admin.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Market: only a module admin can call this function.");
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

    /// @dev Lets a token owner list tokens for sale: Direct Listing or Auction.
    function createListing(
        ListingParameters memory _params
    ) 
        external
        override
        whenNotPaused
        onlyListerRoleWhenRestricted 
    {

        uint256 listingId = nextListingId();
        address tokenOwner = _msgSender();
        TokenType tokenTypeOfListing = getTokenType(_params.assetContract);

        require(
            validateOwnershipAndApproval(tokenOwner, _params.assetContract, _params.tokenId, _params.quantityToList, tokenTypeOfListing)
                && _params.quantityToList > 0,
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

            buyoutPricePerToken: _params.buyoutPricePerToken,
            tokensPerBuyer: _params.tokensPerBuyer == 0 ? _params.quantityToList : _params.tokensPerBuyer,            
            
            tokenType: tokenTypeOfListing
        });

        listings[listingId] = newListing;

        emit NewListing(_params.assetContract, _msgSender(), listingId, newListing);
    }

    /// @dev Lets a listing's creator edit the listing's parameters.
    function editListingParametrs(    
        uint256 _listingId,
        uint256 _quantityToList,   
        uint256 _buyoutPricePerToken,
        uint256 _tokensPerBuyer,
        address _currencyToAccept,
        uint256 _secondsUntilStartTime,
        uint256 _secondsUntilEndTime
    ) 
        external
        override
        whenNotPaused
        onlyExistingListing(_listingId)
        onlyListingCreator(_listingId)
    {
        Listing memory targetListing = listings[_listingId];
        uint256 safeNewQuantity = getSafeQuantity(targetListing.tokenType, _quantityToList);

        targetListing.currency = _currencyToAccept;
        targetListing.tokensPerBuyer = _tokensPerBuyer;
        targetListing.buyoutPricePerToken = _buyoutPricePerToken;
        targetListing.startTime = _secondsUntilStartTime == 0
            ? targetListing.startTime
            : block.timestamp + _secondsUntilStartTime;
        targetListing.endTime = _secondsUntilEndTime == 0
            ? targetListing.endTime
            : block.timestamp + _secondsUntilEndTime;
        
        if(targetListing.quantity != _quantityToList) {
            require(
                validateOwnershipAndApproval(
                    targetListing.tokenOwner, 
                    targetListing.assetContract, 
                    targetListing.tokenId, 
                    safeNewQuantity, 
                    targetListing.tokenType
                ), 
                "Market: must own and approve to transfer tokens."
            );
            targetListing.quantity = safeNewQuantity;
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
        override
        whenNotPaused
        onlyExistingListing(_listingId)
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

    /// @dev Lets an account offer a price for a given amount of tokens.
    function offer(
        uint256 _listingId, 
        uint256 _quantityWanted, 
        uint256 _totalOfferAmount
    ) 
        external
        override
        whenNotPaused
        onlyExistingListing(_listingId)
    {
        address offeror = _msgSender();
        Listing memory targetListing = listings[_listingId];

        validateCurrencyBalAndApproval(
            offeror, 
            targetListing.currency, 
            _totalOfferAmount
        );

        Offer memory newOffer = Offer({
            listingId: _listingId,
            offeror: offeror,
            quantityWanted: getSafeQuantity(targetListing.tokenType, _quantityWanted),
            offerAmount: _totalOfferAmount
        });

        offers[_listingId][offeror] = newOffer;

        emit NewOffer(_listingId, offeror, newOffer, targetListing);
    }

    /// @dev Lets a listing's creator accept an offer for their direct listing.
    function acceptOffer(
        uint256 _listingId, 
        address offeror
    ) 
        external
        override
        whenNotPaused
        onlyListingCreator(_listingId)
    {
        Offer memory targetOffer = offers[_listingId][offeror];
        Listing memory targetListing = listings[_listingId];

        require(
            validateOwnershipAndApproval(
                targetListing.tokenOwner, 
                targetListing.assetContract, 
                targetListing.tokenId, 
                targetOffer.quantityWanted, 
                targetListing.tokenType
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

    //  =====   Internal functions  =====

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
            IERC721(_listing.assetContract).safeTransferFrom(_listing.tokenOwner, _to, _listing.tokenId, "");
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
        uint256 marketCut = (_totalPayoutAmount * marketFeeBps) / controlCenter.MAX_BPS();

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

                remainder = remainder - royaltyAmount;

                transferSuccess = IERC20(_listing.currency).transferFrom(_payer, royaltyReceiver, royaltyAmount);
            }
        }

        // Distribute price to token owner
        transferSuccess = IERC20(_listing.currency).transferFrom(_payer, _payee, remainder);

        require(transferSuccess, "Market: failed to payout stakeholders.");
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
        view
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
        view
    {
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
            "Market: cannot buy tokens from this listing."
        );
        validateCurrencyBalAndApproval(
            _buyer, 
            _listing.currency, 
            _quantityToBuy * _listing.buyoutPricePerToken
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
            revert("Market: token must implement either ERC 1155 or ERC 721.");
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
    function setMarketFeeBps(uint128 feeBps) external onlyModuleAdmin {
        marketFeeBps = feeBps;
        emit MarketFeeUpdate(feeBps);
    }

    /// @dev Lets a module admin restrict listing by LISTER_ROLE.
    function setRestrictedListerRoleOnly(bool restricted) external onlyModuleAdmin {
        restrictedListerRoleOnly = restricted;
        emit RestrictedListerRoleUpdated(restricted);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _uri) external onlyProtocolAdmin {
        _contractURI = _uri;
    }

    /// @dev Lets an account with PAUSER_ROLE pause or unpause the contract.
    function setPaused(bool _toPause) external onlyPauser {
        if(_toPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    //  ===== Getter functions  =====

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Returns the listing for the given seller and Listing ID.
    function getListing(uint256 _listingId) external view returns (Listing memory listing) {
        listing = listings[_listingId];
    }

    /**
     *   See ERC 165
     **/


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}