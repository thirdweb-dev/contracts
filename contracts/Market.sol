// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IProtocolControl, IListingAsset } from "./Interfaces.sol";

contract Market is IERC1155Receiver, ReentrancyGuard {

  /// @dev The pack protocol admin contract.
  IProtocolControl internal controlCenter;

  /// @dev Pack protocol module names.
  string public constant PACK = "PACK";

  /// @dev Pack protocol fee constants.
  uint public constant MAX_BPS = 10000; // 100%
  uint public protocolFeeBps = 500; // 5%
  uint public creatorFeeBps = 500; // 5%

  struct Listing {
    address seller;

    address assetContract;
    uint tokenId;

    uint quantity;
    address currency;
    uint pricePerToken;
  }

  struct SaleWindow {
    uint start;
    uint end;
  }

  /// @dev seller address => total number of listings.
  mapping(address => uint) public totalListings;

  /// @dev seller address + listingId => listing info.
  mapping(address => mapping(uint => Listing)) public listings;

  /// @dev seller address + listingId => sale window for listing.
  mapping(address => mapping(uint => SaleWindow)) public saleWindow;

  /// @dev Events
  event NewListing(address indexed assetContract, address indexed seller, uint listingId, uint tokenId, address currency, uint price, uint quantity);
  event NewSale(address indexed assetContract, address indexed seller, uint indexed listingId, address buyer, uint tokenId, address currency, uint price, uint quantity);
  event ListingUpdate(address indexed seller, uint indexed listingId, uint tokenId, address currency, uint price, uint quantity);
  event SaleWindowUpdate(address indexed seller, uint indexed listingId, uint start, uint end);

  /// @dev Checks whether Pack protocol is paused.
  modifier onlyUnpausedProtocol() {
    require(!controlCenter.systemPaused(), "Market: The pack protocol is paused.");
    _;
  }

  /// @dev Check whether the listing exists.
  modifier onlyExistingListing(address _seller, uint _listingId) {
    require(listings[_seller][_listingId].seller != address(0), "Market: The listing does not exist.");
    _;
  }

  constructor(address _controlCenter) {
    controlCenter = IProtocolControl(_controlCenter);
  }

  /**
  *   ERC 1155 Receiver functions.
  **/

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
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
    uint _tokenId,

    address _currency,
    uint _pricePerToken,
    uint _quantity,

    uint _secondsUntilStart,
    uint _secondsUntilEnd
  ) external onlyUnpausedProtocol {

    // Only an EOA seller can initiate a listing.
    address seller = tx.origin;

    require(IERC1155(_assetContract).isApprovedForAll(seller, address(this)), "Market: must approve the market to transfer tokens being listed.");
    require(_quantity > 0, "Market: must list at least one token.");

    // Transfer tokens being listed to Pack Protocol's asset safe.
    IERC1155(_assetContract).safeTransferFrom(
      seller,
      address(this),
      _tokenId,
      _quantity,
      ""
    );

    // Get listing ID.
    uint listingId = totalListings[seller];
    totalListings[seller] += 1;

    // Create listing.
    listings[seller][listingId] = Listing({
      seller: seller,
      assetContract: _assetContract,
      tokenId: _tokenId,
      currency: _currency,
      pricePerToken: _pricePerToken,
      quantity: _quantity
    });

    emit NewListing(_assetContract, seller, listingId, _tokenId, _currency, _pricePerToken, _quantity);
    
    // Set sale window for listing.
    saleWindow[seller][listingId].start =  block.timestamp + _secondsUntilStart;
    saleWindow[seller][listingId].end = _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd;

    emit SaleWindowUpdate(seller, listingId, saleWindow[seller][listingId].start, saleWindow[seller][listingId].end);
  }

  /// @notice Unlist `_quantity` amount of tokens.
  function unlist(uint _listingId, uint _quantity) external onlyExistingListing(msg.sender, _listingId) {
    require(listings[msg.sender][_listingId].quantity >= _quantity, "Market: cannot unlist more tokens than are listed.");

    // Transfer way tokens being unlisted.
    IERC1155(listings[msg.sender][_listingId].assetContract).safeTransferFrom(address(this), msg.sender, listings[msg.sender][_listingId].tokenId, _quantity, "");

    // Update listing info.
    listings[msg.sender][_listingId].quantity -= _quantity;

    emit ListingUpdate(
      msg.sender,
      _listingId,
      listings[msg.sender][_listingId].tokenId,
      listings[msg.sender][_listingId].currency,
      listings[msg.sender][_listingId].pricePerToken,
      listings[msg.sender][_listingId].quantity
    );
  }

  /// @notice Lets a seller add tokens to an existing listing.
  function addToListing(uint _listingId, uint _quantity) external onlyUnpausedProtocol onlyExistingListing(msg.sender, _listingId) {
    require(
      IERC1155(listings[msg.sender][_listingId].assetContract).isApprovedForAll(msg.sender, address(this)),
      "Market: must approve the market to transfer tokens being added."
    );
    require(_quantity > 0, "Market: must add at least one token.");

    // Transfer tokens being listed to Pack Protocol's asset manager.
    IERC1155(listings[msg.sender][_listingId].assetContract).safeTransferFrom(
      msg.sender,
      address(this),
      listings[msg.sender][_listingId].tokenId,
      _quantity,
      ""
    );

    // Update listing info.
    listings[msg.sender][_listingId].quantity += _quantity;

    emit ListingUpdate(
      msg.sender,
      _listingId,
      listings[msg.sender][_listingId].tokenId,
      listings[msg.sender][_listingId].currency,
      listings[msg.sender][_listingId].pricePerToken,
      listings[msg.sender][_listingId].quantity
    );
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function updateListingPrice(uint _listingId, uint _newPricePerToken) external onlyExistingListing(msg.sender, _listingId) {

    // Update listing info.
    listings[msg.sender][_listingId].pricePerToken = _newPricePerToken;

    emit ListingUpdate(
      msg.sender,
      _listingId,
      listings[msg.sender][_listingId].tokenId,
      listings[msg.sender][_listingId].currency, 
      listings[msg.sender][_listingId].pricePerToken, 
      listings[msg.sender][_listingId].quantity
    );
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function updateListingCurrency(uint _listingId, address _newCurrency) external onlyExistingListing(msg.sender, _listingId) {

    // Update listing info.
    listings[msg.sender][_listingId].currency = _newCurrency;

    emit ListingUpdate(
      msg.sender,
      _listingId,
      listings[msg.sender][_listingId].tokenId,
      listings[msg.sender][_listingId].currency, 
      listings[msg.sender][_listingId].pricePerToken, 
      listings[msg.sender][_listingId].quantity
    );
  }

  /// @notice Lets a seller change the order limit for a listing.
  function updateSaleWindow(uint _listingId, uint _secondsUntilStart, uint _secondsUntilEnd) external onlyExistingListing(msg.sender, _listingId) {

    // Set sale window for listing.
    saleWindow[msg.sender][_listingId].start =  block.timestamp + _secondsUntilStart;
    saleWindow[msg.sender][_listingId].end = _secondsUntilEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilEnd;

    emit SaleWindowUpdate(msg.sender, _listingId, saleWindow[msg.sender][_listingId].start, saleWindow[msg.sender][_listingId].end);
  }

  /// @notice Lets buyer buy a given amount of tokens listed for sale.
  function buy(address _seller, uint _listingId, uint _quantity) external payable nonReentrant onlyExistingListing(_seller, _listingId) {

    require(
      block.timestamp <= saleWindow[_seller][_listingId].end && block.timestamp >= saleWindow[_seller][_listingId].start,
      "Market: the sale has either not started or closed."
    );

    // Determine whether the asset listed is a pack or reward.
    address assetContract = listings[_seller][_listingId].assetContract;
    
    // Get listing
    Listing memory listing = listings[_seller][_listingId];
    
    require(listing.seller != address(0), "Market: the listing does not exist.");
    require(_quantity <= listing.quantity, "Market: trying to buy more tokens than are listed.");

    // Transfer tokens to buyer.
    IERC1155(assetContract).safeTransferFrom(address(this), msg.sender, listing.tokenId, _quantity, "");

    // Update listing info.
    listings[_seller][_listingId].quantity -= _quantity;

    // Get token creator.
    address creator = IListingAsset(assetContract).creator(listing.tokenId);
    
    // Distribute sale value to seller, creator and protocol.
    if(listing.currency == address(0)) {
      distributeEther(listing.seller, creator, listing.pricePerToken, _quantity);
    } else {
      distributeERC20(listing.seller, msg.sender, creator, listing.currency, listing.pricePerToken, _quantity);
    }

    emit NewSale(assetContract, _seller, _listingId,  msg.sender, listing.tokenId, listing.currency, listing.pricePerToken, _quantity);
  }

  /// @notice Distributes relevant shares of the sale value (in ERC20 token) to the seller, creator and protocol.
  function distributeERC20(address seller, address buyer, address creator, address currency, uint price, uint quantity) internal {
    
    // Get value distribution parameters.
    uint totalPrice = price * quantity;
    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;
    
    require(
      IERC20(currency).allowance(buyer, address(this)) >= totalPrice, 
      "Market: must approve Market to transfer price to pay."
    );

    // Distribute relveant shares of sale value to seller, creator and protocol.
    require(IERC20(currency).transferFrom(buyer, controlCenter.treasury(), protocolCut), "Market: failed to transfer protocol cut.");
    require(IERC20(currency).transferFrom(buyer, seller, sellerCut), "Market: failed to transfer seller cut.");
    require(IERC20(currency).transferFrom(buyer, creator, creatorCut), "Market: failed to transfer creator cut.");
  }

  /// @notice Distributes relevant shares of the sale value (in Ether) to the seller, creator and protocol.
  function distributeEther(address seller, address creator, uint price, uint quantity) internal {
    
    // Get value distribution parameters.
    uint totalPrice = price * quantity;
    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;

    require(msg.value >= totalPrice, "Market: must send enough ether to pay the price.");

    // Distribute relveant shares of sale value to seller, creator and protocol.
    (bool success,) = controlCenter.treasury().call{value: protocolCut}("");
    require(success, "Market: failed to transfer protocol cut.");

    (success,) = seller.call{value: sellerCut}("");
    require(success, "Market: failed to transfer seller cut.");

    (success,) = creator.call{value: creatorCut}("");
    require(success, "Market: failed to transfer creator cut.");
  }

  /// @dev Returns pack protocol's pack ERC1155 contract address.
  function packToken() internal view returns (address) {
    return controlCenter.getModule(PACK);
  }

  /// @notice Returns the total number of listings created by seller.
  function getTotalNumOfListings(address _seller) external view returns (uint numOfListings) {
    numOfListings = totalListings[_seller];
  }

  /// @notice Returns the listing for the given seller and Listing ID.
  function getListing(address _seller, uint _listingId) external view returns (Listing memory listing) {
    listing = listings[_seller][_listingId];
  }

  /// @notice Returns the timestamp when buyer last bought from the listing for the given seller and Listing ID.
  function getSaleWindow(address _seller, uint _listingId) external view returns (uint, uint) {
    return (saleWindow[_seller][_listingId].start, saleWindow[_seller][_listingId].end);
  }
}