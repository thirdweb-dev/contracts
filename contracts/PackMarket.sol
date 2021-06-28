// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./PackERC1155.sol";
import "./PackControl.sol";

contract PackMarket is Ownable, ReentrancyGuard, IERC1155Receiver {

  PackControl internal controlCenter;
  string public constant PACK_ERC1155_MODULE_NAME = "PACK_ERC1155";
  string public constant PACK_HANDLER_MODULE_NAME = "PACK_HANDLER";

  event NewListing(
    address indexed seller, 
    uint indexed tokenId, 
    address currency, 
    uint price, 
    uint quantity
  );
  event NewSale(
    address indexed seller, 
    address indexed buyer, 
    uint indexed tokenId, 
    address currency, 
    uint price, 
    uint quantity
  );
  event ListingUpdate(
    address indexed seller, 
    uint indexed tokenId, 
    address currency, 
    uint price, 
    uint quantity
  );
  event Unlisted(address indexed seller, uint indexed tokenId, uint quantity);

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

  // owner => tokenId => Listing
  mapping(address => mapping(uint => Listing)) public listings;

  modifier onlyControlCenter() {
    require(msg.sender == address(controlCenter), "Only the protocol control center can call this function.");
    _;
  }

  modifier eligibleToList(uint tokenId, uint _quantity) {
    require(
      PackERC1155(
        controlCenter.getModule(PACK_ERC1155_MODULE_NAME)
      ).isApprovedForAll(msg.sender, address(this)),
      "Must approve market contract to manage tokens."
    );
    require(
      PackERC1155(
        controlCenter.getModule(PACK_ERC1155_MODULE_NAME)
      ).balanceOf(msg.sender, tokenId) >= _quantity,
      "Must own the amount of tokens being listed."
    );
    require(_quantity > 0, "Must list at least one token");
    _;
  }

  modifier onlySeller(uint tokenId) {
    require(listings[msg.sender][tokenId].owner != address(0), "Only the seller can modify the listing.");
    _;
  }

  constructor(address _controlCenter) {
    controlCenter = PackControl(_controlCenter);
  }

  function initPackListing(
    uint tokenId, 
    address currency, 
    uint price
  ) external {

    (address creator,,,uint circulatingSupply) = PackERC1155(controlCenter.getModule(PACK_ERC1155_MODULE_NAME)).tokens(tokenId);

    require(circulatingSupply == 0, "This function can only be called once, right after pack creation.");
    require(
      msg.sender == creator || msg.sender == controlCenter.getModule(PACK_HANDLER_MODULE_NAME),
      "Only the creator or pack handler can call this function."
    );
  }

  /**
   * @notice Lets pack or reward token owner list a given amount of tokens for sale.
   *
   * @param tokenId The ERC1155 tokenId of the token being listed for sale.
   * @param currency The smart contract address of the desired ERC20 token accepted for sale.
   * @param price The price of each unit of token listed for sale.
   * @param quantity The number of ERC1155 tokens of id `tokenId` being listed for sale.
   */
  function list(
    uint tokenId, 
    address currency, 
    uint price, 
    uint quantity
  ) external eligibleToList(tokenId, quantity) {

    PackERC1155(
      controlCenter.getModule(PACK_ERC1155_MODULE_NAME)
    ).safeTransferFrom(
      msg.sender,
      address(this),
      tokenId,
      quantity,
      ""
    );

    listings[msg.sender][tokenId] = Listing({
      owner: msg.sender,
      tokenId: tokenId,
      currency: currency,
      price: price,
      quantity: quantity
    });

    emit NewListing(msg.sender, tokenId, currency, price, quantity);
  }

  /**
   * @notice Lets a seller set unlist `quantity` amount of tokens.
   *
   * @param tokenId The ERC1155 tokenId of the token being unlisted.
   * @param quantity The amount of tokens to unlist.
   */
  function unlist(uint tokenId, uint quantity) external onlySeller(tokenId) {
    require(listings[msg.sender][tokenId].quantity >= quantity, "Cannot unlist more tokens than are listed.");

    PackERC1155(
      controlCenter.getModule(PACK_ERC1155_MODULE_NAME)
    ).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId,
      quantity,
      ""
    );

    emit Unlisted(msg.sender, tokenId, quantity);
  }

  /**
   * @notice Lets a seller change the currency and price of a listing.
   * 
   * @param tokenId The ERC1155 tokenId associated with the listing.
   * @param _newCurrency The new currency for the listing. 
   * @param _newPrice The new price for the listing.
   */
  function setPriceStatus(uint tokenId, address _newCurrency, uint _newPrice) external onlySeller(tokenId) {
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

  /**
   * @notice Lets buyer buy a given amount of tokens listed for sale in the relevant listing.
   *
   * @param from The address of the listing's seller.
   * @param tokenId The ERC1155 tokenId associated with the listing.
   * @param quantity The quantity of tokens to buy from the relevant listing.
   */
  function buy(address from, uint tokenId, uint quantity) external payable nonReentrant {
    require(listings[from][tokenId].owner != address(0), "The listing does not exist.");
    require(quantity <= listings[from][tokenId].quantity, "attempting to buy more tokens than listed");

    Listing memory listing = listings[from][tokenId];
    (address creator,,,) = PackERC1155(
      controlCenter.getModule(PACK_ERC1155_MODULE_NAME)
    ).tokens(tokenId);
    
    if(listing.currency == address(0)) {
      distributeEther(listing.owner, creator, listing.price, quantity);
    } else {
      distributeERC20(listing.owner, creator, listing.currency, listing.price, quantity);
    }

    PackERC1155(
      controlCenter.getModule(PACK_ERC1155_MODULE_NAME)
    ).safeTransferFrom(listing.owner, msg.sender, tokenId, quantity, "");
    listings[from][tokenId].quantity -= quantity;

    emit NewSale(from, msg.sender, tokenId, listing.currency, listing.price, quantity);
  }

  /**
   * @notice Distributes some share of the sale value (in ERC20 token) to the seller, creator and protocol.
   *
   * @param seller The seller associated with the listing.
   * @param creator The creator of the ERC1155 token on sale.
   * @param currency The ERC20 curreny accepted by the listing.
   * @param price The price per ERC1155 token of the listing.
   * @param quantity The quantity of ERC1155 tokens being purchased.  
   */
  function distributeERC20(address seller, address creator, address currency, uint price, uint quantity) internal {
    uint totalPrice = price * quantity;
    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;

    IERC20 priceToken = IERC20(currency);
    priceToken.approve(address(this), sellerCut + creatorCut);
    require(
      priceToken.allowance(msg.sender, address(this)) >= totalPrice, 
      "Not approved PackMarket to handle price amount."
    );

    require(priceToken.transferFrom(msg.sender, address(this), totalPrice), "ERC20 price transfer failed.");
    require(priceToken.transferFrom(address(this), seller, sellerCut), "ERC20 price transfer failed.");
    if (creatorCut > 0) {
      require(priceToken.transferFrom(address(this), creator, creatorCut), "ERC20 price transfer failed.");
    }
  }

  /**
   * @notice Distributes some share of the sale value (in Ether) to the seller, creator and protocol.
   *
   * @param seller The seller associated with the listing.
   * @param creator The creator of the ERC1155 token on sale.
   * @param price The price per ERC1155 token of the listing.
   * @param quantity The quantity of ERC1155 tokens being purchased.
   */
  function distributeEther(address seller, address creator, uint price, uint quantity) internal {
    uint totalPrice = price * quantity;
    uint protocolCut = (totalPrice * protocolFeeBps) / MAX_BPS;
    uint creatorCut = seller == creator ? 0 : (totalPrice * creatorFeeBps) / MAX_BPS;
    uint sellerCut = totalPrice - protocolCut - creatorCut;

    require(msg.value >= totalPrice, "Must sent enough eth to buy the given amount.");

    (bool success,) = seller.call{value: sellerCut}("");
    require(success, "ETH transfer of seller cut failed.");
    if (creatorCut > 0) {
        (success,) = creator.call{value: creatorCut}("");
      require(success, "ETH transfer of creator cut failed.");
    }
  }

  function transferProtocolFees(address _to, address _currency, uint _amount) public {
    require(msg.sender == address(controlCenter), "Only the treasury contract can transfer protocol fees.");

    if(_currency == address(0)) {
      IERC20 feeToken = IERC20(_currency);
      require(feeToken.balanceOf(address(this)) >= _amount, "Not enough fees generated to withdraw the specified amount.");

      feeToken.approve(address(this), _amount);
      require(
        feeToken.transfer(_to, _amount),
        "ERC20 withdrawal of protocol fees failed."
      );
    } else {
      require(address(this).balance >= _amount, "Not enough fees generated to withdraw the specified amount.");

      (bool success,) = (_to).call{value: _amount}("");
      require(success, "ETH withdrawal of protocol fees failed.");
    }
  }

  /// @dev See `IERC1155Receiver.sol` and `IERC165.sol`
  function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
      return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
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