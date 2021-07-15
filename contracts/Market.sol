// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ListingAsset {
  function creator(uint _tokenId) external view returns (address creator);
}

interface AssetSafe {
  function transferERC1155(address _asset, address _to, uint _tokenId, uint _amount) external;
}

interface ControlCenter {
  function treasury() external view returns(address treasuryAddress);
  function getModule(string memory _moduleName) external view returns (address);
}

contract Market is ReentrancyGuard {

  ControlCenter internal controlCenter;

  string public constant PACK = "PACK";
  string public constant HANDLER = "HANDLER";
  string public constant ASSET_SAFE = "ASSET_SAFE";

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

  struct OrderLimit {
    uint quantityLimit;
    uint timeLimitInSeconds;

    // Buyer => timestamp of last buy.
    mapping(address => uint) lastBuy;
  }

  struct Seller {
    // Total number of listings by seller. Also operates as Listing ID.
    uint totalListings;

    // Listing ID => Listing
    mapping(uint => Listing) listings;
    // Listing ID => Order limit per buyer.
    mapping(uint => OrderLimit) orderLimits;
  }

  /// @dev seller address => Seller state.
  mapping(address => Seller) public sellerListings;

  event NewListing(address indexed assetContract, address indexed seller, uint listingId, uint tokenId, address currency, uint price, uint quantity);
  event NewSale(address indexed seller, address indexed buyer, uint indexed listingId, uint tokenId, address currency, uint price, uint quantity);
  event ListingUpdate(address indexed seller, uint indexed listingId, uint tokenId, address currency, uint price, uint quantity);
  event OrderLimitUpdate(address indexed seller, uint indexed listingId, uint quantityLimit, uint timeLimitInSeconds);

  constructor(address _controlCenter) {
    controlCenter = ControlCenter(_controlCenter);
  }

  /// @notice List a given amount of pack or reward tokens for sale.
  function list(
    address _assetContract, 
    uint _tokenId,

    address _currency,
    uint _pricePerToken,
    uint _quantity,

    uint _quantityLimit, 
    uint _timeLimitInSeconds
  ) external {

    // Only an EOA seller can initiate a listing.
    address seller = tx.origin;
    // Determine whether the asset being listed is a pack or reward.
    address assetContract = _assetContract == address(0) ? packToken() : _assetContract;

    require(IERC1155(assetContract).isApprovedForAll(seller, address(this)), "Must approve the market to transfer tokens being listed.");
    require(_quantity > 0, "Must list at least one token.");

    // Transfer tokens being listed to Pack Protocol's asset safe.
    IERC1155(assetContract).safeTransferFrom(
      seller,
      assetSafe(),
      _tokenId,
      _quantity,
      ""
    );

    // Get listing ID.
    uint listingId = sellerListings[seller].totalListings;
    sellerListings[seller].totalListings += 1;

    // Create listing.
    sellerListings[seller].listings[listingId] = Listing({
      seller: seller,
      assetContract: _assetContract,
      tokenId: _tokenId,
      currency: _currency,
      pricePerToken: _pricePerToken,
      quantity: _quantity
    });

    emit NewListing(_assetContract, seller, listingId, _tokenId, _currency, _pricePerToken, _quantity);
    
    // Set order limit for listing.
    sellerListings[seller].orderLimits[listingId].quantityLimit =  _quantityLimit;
    sellerListings[seller].orderLimits[listingId].timeLimitInSeconds = _timeLimitInSeconds;

    emit OrderLimitUpdate(seller, listingId, _quantityLimit, _timeLimitInSeconds);
  }

  /// @notice Unlist `quantity` amount of tokens.
  function unlist(uint _listingId, uint _quantity) external {

    // Only an EOA seller can update a listing.
    address seller = tx.origin;
    // Determine whether the asset listed is a pack or reward.
    address assetContract = sellerListings[seller].listings[_listingId].assetContract == address(0) ? packToken() : sellerListings[seller].listings[_listingId].assetContract;
    
    require(sellerListings[seller].listings[_listingId].quantity >= _quantity, "Cannot unlist more tokens than are listed.");

    // Transfer way tokens being unlisted.
    AssetSafe(assetSafe()).transferERC1155(assetContract, seller, sellerListings[seller].listings[_listingId].tokenId, _quantity);

    // Update listing info.
    sellerListings[seller].listings[_listingId].quantity -= _quantity;

    emit ListingUpdate(
      seller,
      _listingId,
      sellerListings[seller].listings[_listingId].tokenId,
      sellerListings[seller].listings[_listingId].currency,
      sellerListings[seller].listings[_listingId].pricePerToken,
      sellerListings[seller].listings[_listingId].quantity
    );
  }

  /// @notice Lets a seller add tokens to an existing listing.
  function addToListing(uint _listingId, uint _quantity) external {

    // Only an EOA seller can update a listing.
    address seller = tx.origin;
    // Determine whether the asset listed is a pack or reward.
    address assetContract = sellerListings[seller].listings[_listingId].assetContract == address(0) ? packToken() : sellerListings[seller].listings[_listingId].assetContract;

    require(IERC1155(assetContract).isApprovedForAll(seller, address(this)), "Must approve the market to transfer tokens being added.");
    require(_quantity > 0, "Must add at least one token.");

    // Transfer tokens being listed to Pack Protocol's asset manager.
    IERC1155(assetContract).safeTransferFrom(
      seller,
      assetSafe(),
      sellerListings[seller].listings[_listingId].tokenId,
      _quantity,
      ""
    );

    // Update listing info.
    sellerListings[seller].listings[_listingId].quantity += _quantity;

    emit ListingUpdate(
      seller,
      _listingId,
      sellerListings[seller].listings[_listingId].tokenId,
      sellerListings[seller].listings[_listingId].currency,
      sellerListings[seller].listings[_listingId].pricePerToken,
      sellerListings[seller].listings[_listingId].quantity
    );
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function updateListingPrice(uint _listingId, uint _newPricePerToken) external {
    
    // Only an EOA seller can update a listing.
    address seller = tx.origin;

    // Update listing info.
    sellerListings[seller].listings[_listingId].pricePerToken = _newPricePerToken;

    emit ListingUpdate(
      seller,
      _listingId,
      sellerListings[seller].listings[_listingId].tokenId,
      sellerListings[seller].listings[_listingId].currency, 
      sellerListings[seller].listings[_listingId].pricePerToken, 
      sellerListings[seller].listings[_listingId].quantity
    );
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function updateListingCurrency(uint _listingId, address _newCurrency) external {
    
    // Only an EOA seller can update a listing.
    address seller = tx.origin;

    // Update listing info.
    sellerListings[seller].listings[_listingId].currency = _newCurrency;

    emit ListingUpdate(
      seller,
      _listingId,
      sellerListings[seller].listings[_listingId].tokenId,
      sellerListings[seller].listings[_listingId].currency, 
      sellerListings[seller].listings[_listingId].pricePerToken, 
      sellerListings[seller].listings[_listingId].quantity
    );
  }

  /// @notice Lets a seller change the order limit for a listing.
  function updateOrderLimit(uint _listingId, uint _newQuantityLimit, uint _newTimeLimit) external {

    // Only an EOA seller can update a listing.
    address seller = tx.origin;

    // Update listing order limit.
    sellerListings[seller].orderLimits[_listingId].quantityLimit = _newQuantityLimit;
    sellerListings[seller].orderLimits[_listingId].timeLimitInSeconds = _newTimeLimit;

    emit OrderLimitUpdate(seller, _listingId, _newQuantityLimit, _newTimeLimit);
  }

  /// @notice Lets buyer buy a given amount of tokens listed for sale.
  function buy(address _seller, uint _listingId, uint _quantity) external payable nonReentrant {

    // Only an EOA buyer can buy the listing tokens.
    address buyer = tx.origin;
    // Determine whether the asset listed is a pack or reward.
    address assetContract = sellerListings[_seller].listings[_listingId].assetContract == address(0) ? packToken() : sellerListings[_seller].listings[_listingId].assetContract;
    
    // Get listing
    Listing memory listing = sellerListings[_seller].listings[_listingId];
    
    require(listing.seller != address(0), "The listing does not exist.");
    require(_quantity <= listing.quantity, "Trying to buy more tokens than are listed.");
    require(_quantity <= sellerListings[_seller].orderLimits[_listingId].quantityLimit, "Cannot buy more tokens than the specified limit.");
    require(
      sellerListings[_seller].orderLimits[_listingId].lastBuy[buyer] + sellerListings[_seller].orderLimits[_listingId].timeLimitInSeconds <= block.timestamp, 
      "Must wait before you can buy more tokens."
    );

    // Update last buy from buyer.
    sellerListings[_seller].orderLimits[_listingId].lastBuy[buyer] = block.timestamp;

    // Transfer tokens to buyer.
    AssetSafe(assetSafe()).transferERC1155(assetContract, buyer, listing.tokenId, _quantity);

    // Update listing info.
    sellerListings[_seller].listings[_listingId].quantity -= _quantity;

    // Get token creator.
    address creator = ListingAsset(assetContract).creator(listing.tokenId);
    
    // Distribute sale value to seller, creator and protocol.
    if(listing.currency == address(0)) {
      distributeEther(listing.seller, creator, listing.pricePerToken, _quantity);
    } else {
      distributeERC20(listing.seller, buyer, creator, listing.currency, listing.pricePerToken, _quantity);
    }

    emit NewSale(_seller, buyer, _listingId, listing.tokenId, listing.currency, listing.pricePerToken, _quantity);
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
      "Must approve Market to transfer price to pay."
    );

    // Distribute relveant shares of sale value to seller, creator and protocol.
    require(IERC20(currency).transferFrom(buyer, controlCenter.treasury(), protocolCut), "Failed to transfer protocol cut.");
    require(IERC20(currency).transferFrom(buyer, seller, sellerCut), "Failed to transfer seller cut.");
    require(IERC20(currency).transferFrom(buyer, creator, creatorCut), "Failed to transfer creator cut.");
  }

  /// @notice Distributes relevant shares of the sale value (in Ether) to the seller, creator and protocol.
  function distributeEther(address seller, address creator, uint price, uint quantity) internal {
    
    // Get value distribution parameters.
    uint totalPrice = price * quantity;
    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;

    require(msg.value >= totalPrice, "Must send enough ether to pay the price.");

    // Distribute relveant shares of sale value to seller, creator and protocol.
    (bool success,) = controlCenter.treasury().call{value: protocolCut}("");
    require(success, "Failed to transfer protocol cut.");

    (success,) = seller.call{value: sellerCut}("");
    require(success, "Failed to transfer seller cut.");

    (success,) = creator.call{value: creatorCut}("");
    require(success, "Failed to transfer creator cut.");
  }

  /// @dev Returns pack protocol's pack ERC1155 contract address.
  function packToken() internal view returns (address) {
    return controlCenter.getModule(PACK);
  }

  /// @dev Returns pack protocol's asset manager address.
  function assetSafe() internal view returns (address) {
    return controlCenter.getModule(ASSET_SAFE);
  }

  /// @notice Returns the total number of listings created by seller.
  function getTotalNumOfListings(address _seller) external view returns (uint numOfListings) {
    numOfListings = sellerListings[_seller].totalListings;
  }

  /// @notice Returns the listing for the given seller and Listing ID.
  function getListing(address _seller, uint _listingId) external view returns (Listing memory listing) {
    listing = sellerListings[_seller].listings[_listingId];
  }

  /// @notice Returns the order limit for the given seller and Listing ID.
  function getOrderLimit(address _seller, uint _listingId) external view returns (uint quantityLimit, uint timeLimitInSeconds) {
    quantityLimit = sellerListings[_seller].orderLimits[_listingId].quantityLimit;
    timeLimitInSeconds = sellerListings[_seller].orderLimits[_listingId].timeLimitInSeconds;
  }

  /// @notice Returns the timestamp when buyer last bought from the listing for the given seller and Listing ID.
  function getLastBuy(address _seller, address _buyer, uint _listingId) external view returns (uint lastBuy) {
    lastBuy = sellerListings[_seller].orderLimits[_listingId].lastBuy[_buyer];
  }
}