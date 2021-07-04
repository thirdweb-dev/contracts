// ░█████╗░  ░█████╗░  ░█████╗░  ███████╗  ░██████╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██╔════╝  ██╔════╝  ██╔════╝
// ███████║  ██║░░╚═╝  ██║░░╚═╝  █████╗░░  ╚█████╗░  ╚█████╗░
// ██╔══██║  ██║░░██╗  ██║░░██╗  ██╔══╝░░  ░╚═══██╗  ░╚═══██╗
// ██║░░██║  ╚█████╔╝  ╚█████╔╝  ███████╗  ██████╔╝  ██████╔╝
// ╚═╝░░╚═╝  ░╚════╝░  ░╚════╝░  ╚══════╝  ╚═════╝░  ╚═════╝░


// ██████╗░  ░█████╗░  ░█████╗░  ██╗░░██╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██║░██╔╝  ██╔════╝
// ██████╔╝  ███████║  ██║░░╚═╝  █████═╝░  ╚█████╗░
// ██╔═══╝░  ██╔══██║  ██║░░██╗  ██╔═██╗░  ░╚═══██╗
// ██║░░░░░  ██║░░██║  ╚█████╔╝  ██║░╚██╗  ██████╔╝
// ╚═╝░░░░░  ╚═╝░░╚═╝  ░╚════╝░  ╚═╝░░╚═╝  ╚═════╝░

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Handler.sol";
import "../Market.sol";
import "../ControlCenter.sol";

contract AccessPacks is ERC1155PresetMinterPauser, IERC1155Receiver, ReentrancyGuard {

  ControlCenter internal controlCenter;
  string public constant HANDLER = "HANDLER";
  string public constant MARKET = "MARKET";

  uint public currentTokenId;

  uint public constant MAX_BPS = 10000; // 100%
  uint public creatorFeeBps = 500; // 5%

  struct AccessRewards {
    address creator;
    string uri;
    uint supply;
  }

  struct Listing {
    address owner;
    uint rewardId;

    uint quantity;
    address currency;
    uint price;
  }

  event NewListing(address indexed seller, uint indexed tokenId, address currency, uint price, uint quantity);
  event NewSale(address indexed seller, address indexed buyer, uint indexed tokenId, address currency, uint price, uint quantity);
  event ListingUpdate(address indexed seller, uint indexed tokenId, address currency, uint price, uint quantity);
  event Unlisted(address indexed seller, uint indexed tokenId, uint quantity);

  /// @dev Reward tokenId => Reward state.
  mapping(uint => AccessRewards) public accessRewards;

  /// @dev Owner => tokenId => Listing
  mapping(address => mapping(uint => Listing)) public listings;

  modifier onlySeller(uint tokenId) {
    require(listings[msg.sender][tokenId].owner != address(0), "Only the seller can modify the listing.");
    _;
  }

  constructor(address _controlCenter) ERC1155PresetMinterPauser("") {
    controlCenter = ControlCenter(_controlCenter);

    _setupRole(DEFAULT_ADMIN_ROLE, address(this));

    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    revokeRole(MINTER_ROLE, msg.sender);
    revokeRole(PAUSER_ROLE, msg.sender);
  }

  /// @notice Lets `msg.sender` create a pack with rewards and list it for sale.
  function createPackAndList(
    string calldata _packURI,
    string[] calldata _rewardURIs,
    uint[] calldata _rewardSupplies,
    address _saleCurrency,
    uint _salePrice
  ) external {

    require(_rewardURIs.length == _rewardSupplies.length, "Must specify equal number of URIs and supplies.");

    // Get tokenIds and store reward state.
    uint[] memory rewardIds = new uint[](_rewardURIs.length);
    
    for(uint i = 0; i < _rewardURIs.length; i++) {
      rewardIds[i] = currentTokenId;

      accessRewards[currentTokenId] = AccessRewards({
        creator: msg.sender,
        uri: _rewardURIs[i],
        supply: _rewardSupplies[i]
      });

      currentTokenId++;
    }

    // Mint reward tokens to `msg.sender`
    grantRole(MINTER_ROLE, msg.sender);
    mintBatch(msg.sender, rewardIds, _rewardSupplies, "");
    revokeRole(MINTER_ROLE, msg.sender);

    // Call Handler to create packs with rewards.
    (uint packTokenId, uint packSupply) = handler().createPack(_packURI, address(this), rewardIds, _rewardSupplies);

    // Set on sale in Market.
    market().listPacks(packTokenId, _saleCurrency, _salePrice, packSupply);
  }

  /// @notice Lets `msg.sender` list a given amount of reward tokens for sale.
  function listRewards(
    uint _tokenId, 
    address _currency, 
    uint _price, 
    uint _quantity
  ) external {
    require(isApprovedForAll(msg.sender, address(this)), "Must approve the contract to transfer reward tokens.");
    require(_quantity > 0, "Must list at least one reward token.");

    // Transfer tokens being listed to Pack Protocol's asset manager.
    safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      _quantity,
      ""
    );

    // Store listing state.
    listings[msg.sender][_tokenId] = Listing({
      owner: msg.sender,
      rewardId: _tokenId,
      currency: _currency,
      price: _price,
      quantity: _quantity
    });

    emit NewListing(msg.sender, _tokenId, _currency, _price, _quantity);
  }

  /// @notice Lets a seller unlist `quantity` amount of tokens.
  function unlist(uint _tokenId, uint _quantity) external onlySeller(_tokenId) {
    require(listings[msg.sender][_tokenId].quantity >= _quantity, "Cannot unlist more tokens than are listed.");

    // Transfer way tokens being unlisted.
    safeTransferFrom(address(this), msg.sender, _tokenId, _quantity, "");

    emit Unlisted(msg.sender, _tokenId, _quantity);
  }

  /// @notice Lets a seller change the currency or price of a listing.
  function setPriceStatus(uint tokenId, address _newCurrency, uint _newPrice) external onlySeller(tokenId) {
    
    // Store listing state.
    listings[msg.sender][tokenId].price = _newPrice;
    listings[msg.sender][tokenId].currency = _newCurrency;

    emit ListingUpdate(
      msg.sender,
      tokenId,
      listings[msg.sender][tokenId].currency, 
      listings[msg.sender][tokenId].price, 
      listings[msg.sender][tokenId].quantity
    );
  }

  /// @notice Lets buyer buy a given amount of tokens listed for sale.
  function buy(address _from, uint _tokenId, uint _quantity) external payable nonReentrant {

    require(listings[_from][_tokenId].owner != address(0), "The listing does not exist.");
    require(_quantity <= listings[_from][_tokenId].quantity, "Attempting to buy more tokens than are listed.");

    Listing memory listing = listings[_from][_tokenId];
    
    // Distribute sale value to seller, creator and protocol.
    if(listing.currency == address(0)) {
      distributeEther(listing.owner, accessRewards[_tokenId].creator, listing.price, _quantity);
    } else {
      distributeERC20(listing.owner, accessRewards[_tokenId].creator, listing.currency, listing.price, _quantity);
    }

    // Transfer tokens to buyer.
    safeTransferFrom(address(this), msg.sender, _tokenId, _quantity, "");
    
    // Update quantity of tokens in the listing.
    listings[_from][_tokenId].quantity -= _quantity;

    emit NewSale(_from, msg.sender, _tokenId, listing.currency, listing.price, _quantity);
  }

  /// @notice Distributes relevant shares of the sale value (in ERC20 token) to the seller, creator and protocol.
  function distributeERC20(address seller, address creator, address currency, uint price, uint quantity) internal {
    
    // Get value distribution parameters.
    uint totalPrice = price * quantity;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - creatorCut;
    
    require(
      IERC20(currency).allowance(msg.sender, address(this)) >= totalPrice, 
      "Not approved PackMarket to handle price amount."
    );

    // Distribute relveant shares of sale value to seller, creator and protocol.
    require(IERC20(currency).transferFrom(msg.sender, seller, sellerCut), "Failed to transfer seller cut.");

    if (creatorCut > 0) {
      require(IERC20(currency).transferFrom(msg.sender, creator, creatorCut), "Failed to transfer creator cut.");
    }
  }

  /// @notice Distributes relevant shares of the sale value (in Ether) to the seller, creator and protocol.
  function distributeEther(address seller, address creator, uint price, uint quantity) internal {
    
    // Get value distribution parameters.
    uint totalPrice = price * quantity;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - creatorCut;

    require(msg.value >= totalPrice, "Must sent enough eth to buy the given amount.");

    // Distribute relveant shares of sale value to seller, creator and protocol.
    (bool success,) = seller.call{value: sellerCut}("");
    require(success, "Failed to transfer seller cut.");

    if (creatorCut > 0) {
        (success,) = creator.call{value: creatorCut}("");
      require(success, "Failed to transfer creator cut.");
    }
  }

  /// @dev Returns pack protocol's Handler.
  function handler() internal view returns (Handler) {
    return Handler(controlCenter.getModule(HANDLER));
  }

  /// @dev Returns pack protocol's Market.
  function market() internal view returns (Market) {
    return Market(controlCenter.getModule(MARKET));
  }

  /// @dev See `IERC1155Receiver.sol`
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  /// @dev See `IERC1155Receiver.sol`
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
  }
}