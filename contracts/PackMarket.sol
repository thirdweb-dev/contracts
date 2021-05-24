// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Pack.sol";

contract PackMarket is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  event PackTokenChanged(address newPackTokenAddress);
  event PackListed(address indexed seller, uint256 indexed tokenId, address currency, uint256 price, uint256 quantity);
  event PackUnlisted(address indexed seller, uint256 indexed tokenId);
  event ListingUpdate(address indexed seller, uint256 indexed tokenId, address currency, uint256 price, uint256 quantity);
  event PackSold(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 quantity);

  Pack public packToken;

  uint256 public constant MAX_BPS = 10000; // 100%
  uint256 public protocolFeeBps = 500; // 5%
  uint256 public creatorFeeBps = 500; // 5%

  struct Listing {
    address owner;
    uint256 tokenId;

    address currency;
    uint256 price;
    uint256 quantity;
  }

  // owner => tokenId => Listing
  mapping(address => mapping(uint256 => Listing)) public listings;

  constructor(address _packToken) {
    packToken = Pack(_packToken);
  }

  function setPackToken(address _packToken) external onlyOwner {
    packToken = Pack(_packToken);
    emit PackTokenChanged(_packToken);
  }

  function sell(uint256 tokenId, address currency, uint256 price, uint256 quantity) external {
    require(packToken.isApprovedForAll(msg.sender, address(this)), "require token approval");
    require(packToken.balanceOf(msg.sender, tokenId) >= quantity, "seller must own enough tokens");
    require(packToken.isEligibleForSale(tokenId), "attempting to sell unlocked pack");
    require(quantity > 0, "must list at least one token");

    listings[msg.sender][tokenId] = Listing({
      owner: msg.sender,
      tokenId: tokenId,
      currency: currency,
      price: price,
      quantity: quantity
    });

    emit PackListed(msg.sender, tokenId, currency, price, quantity);
  }

  function unlist(uint256 tokenId) external {
    require(listings[msg.sender][tokenId].owner == msg.sender, "listing must exist");
    
    delete listings[msg.sender][tokenId];

    emit PackUnlisted(msg.sender, tokenId);
  }

  function setListingPrice(uint256 _tokenId, uint256 _newPrice) external  {
    require(listings[msg.sender][_tokenId].owner == msg.sender, "listing must exist");

    listings[msg.sender][_tokenId].price = _newPrice;
    
    emit ListingUpdate(
      msg.sender, _tokenId, listings[msg.sender][_tokenId].currency, _newPrice, listings[msg.sender][_tokenId].quantity
    );
  }

  function setListingCurrency(uint256 _tokenId, address _newCurrency) external {
    require(listings[msg.sender][_tokenId].owner == msg.sender, "listing must exist");

    listings[msg.sender][_tokenId].currency = _newCurrency;

    emit ListingUpdate(
      msg.sender, _tokenId, _newCurrency, listings[msg.sender][_tokenId].price, listings[msg.sender][_tokenId].quantity
    );
  }

  function buy(address from, uint256 tokenId, uint256 quantity) external nonReentrant {
    require(from != address(0), "invalid listing owner");
    require(quantity > 0, "must buy at least one token");
    require(quantity <= listings[from][tokenId].quantity, "attempting to buy more tokens than listed");

    Listing memory listing = listings[from][tokenId];
    require(listing.currency != address(0), "invalid price token");

    address creator = packToken.ownerOf(tokenId);
    uint256 totalPrice = listing.price.mul(quantity);
    uint256 protocolCut = totalPrice.mul(protocolFeeBps).div(MAX_BPS);
    uint256 creatorCut = listing.owner == creator ? 0 : totalPrice.mul(creatorFeeBps).div(MAX_BPS);
    uint256 sellerCut = totalPrice - protocolCut - creatorCut;

    IERC20 priceToken = IERC20(listing.currency);
    priceToken.approve(address(this), sellerCut + creatorCut);
    require(
      priceToken.allowance(msg.sender, address(this)) >= totalPrice, 
      "Not approved PackMarket to handle price amount."
    );

    require(priceToken.transferFrom(msg.sender, address(this), totalPrice), "ERC20 price transfer failed.");
    require(priceToken.transferFrom(address(this), listing.owner, sellerCut), "ERC20 price transfer failed.");
    if (creatorCut > 0) {
      require(priceToken.transferFrom(address(this), creator, creatorCut), "ERC20 price transfer failed.");
    }

    packToken.safeTransferFrom(listing.owner, msg.sender, tokenId, quantity, "");

    emit PackSold(from, msg.sender, tokenId, quantity);
  }

  fallback() external payable {}
  receive() external payable {}
}
