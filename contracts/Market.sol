// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

// Security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { Forwarder } from "./Forwarder.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

contract Market is IERC1155Receiver, ReentrancyGuard, ERC2771Context {
    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    // See EIP 2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @dev Total number of listings on market.
    uint256 public totalListings;

    struct Listing {
        address seller;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 pricePerToken;
        uint256 saleStart;
        uint256 saleEnd;
    }

    /// @dev seller address => listingId => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev Events
    event MarketFeesUpdated(uint256 protocolFeeBps, uint256 creatorFeeBps);
    event NewListing(address indexed assetContract, address indexed seller, uint256 indexed listingId, Listing listing);
    event ListingUpdate(address indexed seller, uint256 indexed listingId, Listing listing);
    event NewSale(
        address indexed assetContract,
        address indexed seller,
        uint256 indexed listingId,
        address buyer,
        Listing listing
    );

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "Market: The pack protocol is paused.");
        _;
    }

    /// @dev Check whether the listing exists.
    modifier onlyExistingListing(uint256 _listingId) {
        require(listings[_listingId].seller != address(0), "Market: The listing does not exist.");
        _;
    }

    /// @dev Check whether the function is called by the seller of the listing.
    modifier onlySeller(address _seller, uint256 _listingId) {
        require(listings[_listingId].seller == _seller, "Market: Only the seller can call this function.");
        _;
    }

    constructor(address _controlCenter, address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        controlCenter = ProtocolControl(_controlCenter);
    }

    /**
     *   ERC 1155 Receiver functions.
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

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
     *   External functions.
     **/

    /// @notice List a given amount of pack or reward tokens for sale.
    function list(
        address _assetContract,
        uint256 _tokenId,
        address _currency,
        uint256 _pricePerToken,
        uint256 _quantity,
        uint256 _secondsUntilStart,
        uint256 _secondsUntilEnd
    ) external onlyUnpausedProtocol {
        require(_quantity > 0, "Market: must list at least one token.");
        require(
            IERC1155(_assetContract).isApprovedForAll(_msgSender(), address(this)),
            "Market: must approve the market to transfer tokens being listed."
        );

        // Transfer tokens being listed to Pack Protocol's asset safe.
        IERC1155(_assetContract).safeTransferFrom(_msgSender(), address(this), _tokenId, _quantity, "");

        // Get listing ID.
        uint256 listingId = totalListings;
        totalListings += 1;

        // Create listing.
        Listing memory newListing = Listing({
            seller: _msgSender(),
            assetContract: _assetContract,
            tokenId: _tokenId,
            currency: _currency,
            pricePerToken: _pricePerToken,
            quantity: _quantity,
            saleStart: block.timestamp + _secondsUntilStart,
            saleEnd: _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd
        });

        listings[listingId] = newListing;

        emit NewListing(_assetContract, _msgSender(), listingId, newListing);
    }

    /// @notice Unlist `_quantity` amount of tokens.
    function unlist(uint256 _listingId, uint256 _quantity) external onlySeller(_msgSender(), _listingId) {
        Listing memory listing = listings[_listingId];

        require(listing.quantity >= _quantity, "Market: cannot unlist more tokens than are listed.");

        // Transfer way tokens being unlisted.
        IERC1155(listing.assetContract).safeTransferFrom(address(this), _msgSender(), listing.tokenId, _quantity, "");

        // Update listing info.
        listing.quantity -= _quantity;
        listings[_listingId] = listing;

        emit ListingUpdate(_msgSender(), _listingId, listing);
    }

    /// @notice Lets a seller add tokens to an existing listing.
    function addToListing(uint256 _listingId, uint256 _quantity)
        external
        onlyUnpausedProtocol
        onlySeller(_msgSender(), _listingId)
    {
        Listing memory listing = listings[_listingId];

        require(_quantity > 0, "Market: must add at least one token.");
        require(
            IERC1155(listing.assetContract).isApprovedForAll(_msgSender(), address(this)),
            "Market: must approve the market to transfer tokens being added."
        );

        // Transfer tokens being listed to Pack Protocol's asset manager.
        IERC1155(listing.assetContract).safeTransferFrom(_msgSender(), address(this), listing.tokenId, _quantity, "");

        // Update listing info.
        listing.quantity += _quantity;
        listings[_listingId] = listing;

        emit ListingUpdate(_msgSender(), _listingId, listing);
    }

    /// @notice Lets a seller change the currency or price of a listing.
    function updateListingParams(
        uint256 _listingId,
        uint256 _pricePerToken,
        address _currency,
        uint256 _secondsUntilStart,
        uint256 _secondsUntilEnd
    ) external onlySeller(_msgSender(), _listingId) {
        Listing memory listing = listings[_listingId];

        // Update listing info.
        listing.pricePerToken = _pricePerToken;
        listing.currency = _currency;
        listing.saleStart = block.timestamp + _secondsUntilStart;
        listing.saleEnd = _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd;

        listings[_listingId] = listing;

        emit ListingUpdate(_msgSender(), _listingId, listing);
    }

    /// @notice Lets buyer buy a given amount of tokens listed for sale.
    function buy(uint256 _listingId, uint256 _quantity) external nonReentrant onlyExistingListing(_listingId) {
        // Get listing
        Listing memory listing = listings[_listingId];

        require(_quantity > 0 && _quantity <= listing.quantity, "Market: must buy an appropriate amount of tokens.");
        require(
            block.timestamp <= listing.saleEnd && block.timestamp >= listing.saleStart,
            "Market: the sale has either not started or closed."
        );

        // Update listing info.
        listing.quantity -= _quantity;
        listings[_listingId] = listing;

        // Get value distribution parameters.
        uint256 totalPrice = listing.pricePerToken * _quantity;

        if (listing.pricePerToken > 0) {
            require(
                IERC20(listing.currency).allowance(_msgSender(), address(this)) >= totalPrice,
                "Market: must approve Market to transfer price to pay."
            );
        }

        // Protocol fee
        uint256 protocolCut = (totalPrice * controlCenter.marketFeeBps()) / controlCenter.MAX_BPS();
        require(
            IERC20(listing.currency).transferFrom(_msgSender(), controlCenter.nftlabsTreasury(), protocolCut),
            "Market: failed to transfer protocol cut."
        );

        uint256 sellerCut = totalPrice - protocolCut;

        if (IERC165(listing.assetContract).supportsInterface(_INTERFACE_ID_ERC2981)) {
            (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(listing.assetContract).royaltyInfo(
                listing.tokenId,
                totalPrice
            );

            sellerCut -= royaltyAmount;

            require(
                IERC20(listing.currency).transferFrom(_msgSender(), royaltyReceiver, royaltyAmount),
                "Market: failed to transfer creator cut."
            );
        }

        require(
            IERC20(listing.currency).transferFrom(_msgSender(), listing.seller, sellerCut),
            "Market: failed to transfer seller cut."
        );

        // Transfer tokens being bought to buyer.
        IERC1155(listing.assetContract).safeTransferFrom(address(this), _msgSender(), listing.tokenId, _quantity, "");

        emit NewSale(listing.assetContract, listing.seller, _listingId, _msgSender(), listing);
    }

    /// @notice Returns the listing for the given seller and Listing ID.
    function getListing(uint256 _listingId) external view returns (Listing memory listing) {
        listing = listings[_listingId];
    }
}
