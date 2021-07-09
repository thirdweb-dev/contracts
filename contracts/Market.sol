// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ControlCenter.sol";
import "./Pack.sol";
import "./AssetSafe.sol";

interface IPackRewards {
  function creator(uint _tokenId) external view returns (address);
}

contract Market is ReentrancyGuard {

  ControlCenter internal controlCenter;

  string public constant PACK = "PACK";
  string public constant HANDLER = "HANDLER";
  string public constant ASSET_SAFE = "ASSET_SAFE";

  event NewPackListing(address indexed seller, uint indexed packId, address currency, uint price, uint quantity);
  event NewPackSale(address indexed seller, address indexed buyer, uint indexed packId, address currency, uint price, uint quantity);
  event PackListingUpdate(address indexed seller, uint indexed packId, address currency, uint price, uint quantity);
  event PackUnlisted(address indexed seller, uint indexed packId, uint quantity);

  event NewRewardListing(address indexed rewardContract, address indexed seller, uint indexed rewardId, address currency, uint price, uint quantity);
  event NewRewardSale(address indexed rewardContract, address indexed seller, address indexed buyer, uint rewardId, address currency, uint price, uint quantity);
  event RewardListingUpdate(address indexed rewardContract, address indexed seller, uint indexed packId, address currency, uint price, uint quantity);
  event RewardUnlisted(address indexed rewardContract, address indexed seller, uint indexed packId, uint quantity);

  uint public constant MAX_BPS = 10000; // 100%
  uint public protocolFeeBps = 500; // 5%
  uint public creatorFeeBps = 500; // 5%

  struct Listing {
    address owner;
    uint tokenId;

    uint quantity;
    address currency;
    uint price;
  }

  /// @dev Owner => tokenId => Listing
  mapping(address => mapping(uint => Listing)) public listings;

  /// @dev ERC 1155 contract => owner => tokenId => Listing
  mapping(address => mapping(address => mapping(uint => Listing))) public rewardListings;

  modifier onlySeller(uint tokenId) {
    require(listings[msg.sender][tokenId].owner != address(0), "Only the seller can modify the listing.");
    _;
  }

  modifier onlyHandler() {
    require(msg.sender == controlCenter.getModule(HANDLER), "Only the handler can call this function.");
    _;
  }

  constructor(address _controlCenter) {
    controlCenter = ControlCenter(_controlCenter);
  }

  /// @notice Lets `msg.sender` list a given amount of pack tokens for sale.
  function listPacks(address _onBehalfOf, uint _tokenId, address _currency, uint _price, uint _quantity) external onlyHandler {
    require(packToken().isApprovedForAll(_onBehalfOf, address(this)), "Must approve the market to transfer pack tokens.");
    require(_quantity > 0, "Must list at least one token");

    // Transfer tokens being listed to Pack Protocol's asset manager.
    packToken().safeTransferFrom(
      _onBehalfOf,
      address(assetSafe()),
      _tokenId,
      _quantity,
      ""
    );

    // Store listing state.
    listings[_onBehalfOf][_tokenId] = Listing({
      owner: _onBehalfOf,
      tokenId: _tokenId,
      currency: _currency,
      price: _price,
      quantity: _quantity
    });

    emit NewPackListing(_onBehalfOf, _tokenId, _currency, _price, _quantity);
  }

  /// @notice Lets `msg.sender` list a given amount of pack tokens for sale.
  function listRewards(address _rewardContract, uint _tokenId, address _currency, uint _price, uint _quantity) external {
    
    require(IERC1155(_rewardContract).isApprovedForAll(msg.sender, address(this)), "Must approve the market to transfer pack tokens.");
    require(_quantity > 0, "Must list at least one token");

    // Transfer tokens being listed to Pack Protocol's asset manager.
    IERC1155(_rewardContract).safeTransferFrom(
      msg.sender,
      address(assetSafe()),
      _tokenId,
      _quantity,
      ""
    );

    // Store listing state.
    rewardListings[_rewardContract][msg.sender][_tokenId] = Listing({
      owner: msg.sender,
      tokenId: _tokenId,
      currency: _currency,
      price: _price,
      quantity: _quantity
    });

    emit NewRewardListing(_rewardContract, msg.sender, _tokenId, _currency, _price, _quantity);
  }

  /// @notice Lets a seller unlist `quantity` amount of tokens.
  function unlistPacks(uint _tokenId, uint _quantity) external onlySeller(_tokenId) {
    require(listings[msg.sender][_tokenId].quantity >= _quantity, "Cannot unlist more tokens than are listed.");

    // Transfer way tokens being unlisted.
    assetSafe().transferERC1155(address(packToken()), msg.sender, _tokenId, _quantity);

    emit PackUnlisted(msg.sender, _tokenId, _quantity);
  }

  /// @notice Lets a seller unlist `quantity` amount of tokens.
  function unlistRewards(address _rewardContract, uint _tokenId, uint _quantity) external onlySeller(_tokenId) {
    require(rewardListings[_rewardContract][msg.sender][_tokenId].quantity >= _quantity, "Cannot unlist more tokens than are listed.");

    // Transfer way tokens being unlisted.
    assetSafe().transferERC1155(_rewardContract, msg.sender, _tokenId, _quantity);

    emit RewardUnlisted(_rewardContract, msg.sender, _tokenId, _quantity);
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function setPriceStatusPacks(uint tokenId, address _newCurrency, uint _newPrice) external onlySeller(tokenId) {
    
    // Store listing state.
    listings[msg.sender][tokenId].price = _newPrice;
    listings[msg.sender][tokenId].currency = _newCurrency;

    emit PackListingUpdate(
      msg.sender,
      tokenId,
      listings[msg.sender][tokenId].currency, 
      listings[msg.sender][tokenId].price, 
      listings[msg.sender][tokenId].quantity
    );
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function setPriceStatusRewards(address _rewardContract, uint tokenId, address _newCurrency, uint _newPrice) external onlySeller(tokenId) {
    
    // Store listing state.
    rewardListings[_rewardContract][msg.sender][tokenId].price = _newPrice;
    rewardListings[_rewardContract][msg.sender][tokenId].currency = _newCurrency;

    emit RewardListingUpdate(
      _rewardContract,
      msg.sender,
      tokenId,
      listings[msg.sender][tokenId].currency, 
      listings[msg.sender][tokenId].price, 
      listings[msg.sender][tokenId].quantity
    );
  }

  /// @notice Lets buyer buy a given amount of tokens listed for sale.
  function buyPacks(address _from, uint _tokenId, uint _quantity) external payable nonReentrant {

    require(listings[_from][_tokenId].owner != address(0), "The listing does not exist.");
    require(_quantity <= listings[_from][_tokenId].quantity, "Attempting to buy more tokens than are listed.");

    Listing memory listing = listings[_from][_tokenId];
    
    // Distribute sale value to seller, creator and protocol.
    if(listing.currency == address(0)) {
      distributeEther(listing.owner, packToken().creator(_tokenId), listing.price, _quantity);
    } else {
      distributeERC20(listing.owner, packToken().creator(_tokenId), listing.currency, listing.price, _quantity);
    }

    // Transfer tokens to buyer.
    assetSafe().transferERC1155(address(packToken()),  msg.sender, _tokenId, _quantity);
    
    // Update quantity of tokens in the listing.
    listings[_from][_tokenId].quantity -= _quantity;

    emit NewPackSale(_from, msg.sender, _tokenId, listing.currency, listing.price, _quantity);
  }

  /// @notice Lets buyer buy a given amount of tokens listed for sale.
  function buyRewards(address _rewardContract, address _from, uint _tokenId, uint _quantity) external payable nonReentrant {

    require(
      rewardListings[_rewardContract][_from][_tokenId].owner != address(0),
      "The listing does not exist."
    );
    require(
      _quantity <= rewardListings[_rewardContract][_from][_tokenId].quantity, 
      "Attempting to buy more tokens than are listed."
    );

    Listing memory listing = rewardListings[_rewardContract][_from][_tokenId];

    // Get token creator.
    address creator = IPackRewards(_rewardContract).creator(_tokenId);
    
    // Distribute sale value to seller, creator and protocol.
    if(listing.currency == address(0)) {
      distributeEther(listing.owner, creator, listing.price, _quantity);
    } else {
      distributeERC20(listing.owner, creator, listing.currency, listing.price, _quantity);
    }

    // Transfer tokens to buyer.
    assetSafe().transferERC1155(_rewardContract,  msg.sender, _tokenId, _quantity);
    
    // Update quantity of tokens in the listing.
    rewardListings[_rewardContract][_from][_tokenId].quantity -= _quantity;

    emit NewRewardSale(_rewardContract, _from, msg.sender, _tokenId, listing.currency, listing.price, _quantity);
  }

  /// @notice Distributes relevant shares of the sale value (in ERC20 token) to the seller, creator and protocol.
  function distributeERC20(address seller, address creator, address currency, uint price, uint quantity) internal {
    
    // Get value distribution parameters.
    uint totalPrice = price * quantity;
    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;
    
    require(
      IERC20(currency).allowance(msg.sender, address(this)) >= totalPrice, 
      "Not approved PackMarket to handle price amount."
    );

    // Distribute relveant shares of sale value to seller, creator and protocol.
    require(IERC20(currency).transferFrom(msg.sender, controlCenter.treasury(), protocolCut), "Failed to transfer protocol cut.");
    require(IERC20(currency).transferFrom(msg.sender, seller, sellerCut), "Failed to transfer seller cut.");

    if (creatorCut > 0) {
      require(IERC20(currency).transferFrom(msg.sender, creator, creatorCut), "Failed to transfer creator cut.");
    }
  }

  /// @notice Distributes relevant shares of the sale value (in Ether) to the seller, creator and protocol.
  function distributeEther(address seller, address creator, uint price, uint quantity) internal {
    
    // Get value distribution parameters.
    uint totalPrice = price * quantity;
    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;

    require(msg.value >= totalPrice, "Must send enough eth to buy the given amount.");

    // Distribute relveant shares of sale value to seller, creator and protocol.
    (bool success,) = controlCenter.treasury().call{value: protocolCut}("");
    require(success, "Failed to transfer protocol cut.");

    (success,) = seller.call{value: sellerCut}("");
    require(success, "Failed to transfer seller cut.");

    if (creatorCut > 0) {
        (success,) = creator.call{value: creatorCut}("");
      require(success, "Failed to transfer creator cut.");
    }
  }

  /// @dev Returns pack protocol's reward ERC1155 contract.
  function packToken() internal view returns (Pack) {
    return Pack(controlCenter.getModule(PACK));
  }

  /// @dev Returns pack protocol's asset manager address.
  function assetSafe() internal view returns (AssetSafe) {
    return AssetSafe(controlCenter.getModule(ASSET_SAFE));
  }
}