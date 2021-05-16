pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './Pack.sol';

contract PackMarket is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  event PackTokenChanged(address newPackTokenAddress);
  event PackListed(address indexed seller, uint256 indexed tokenId, address currency, uint256 amount);
  event PackSold(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 quantity);

  Pack public packToken;

  uint256 public constant MAX_BPS = 10000; // 100%
  uint256 public protocolFeeBps = 500; // 5%
  uint256 public creatorFeeBps = 500; // 5%

  struct Listing {
    address owner;
    uint256 tokenId;

    address currency;
    uint256 amount;
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

  function sell(uint256 tokenId, address currency, uint256 amount) external {
    require(packToken.isApprovedForAll(msg.sender, address(this)), "require token approval");
    require(packToken.balanceOf(msg.sender, tokenId) > 0, "require at least 1 token");

    packToken.lockReward(tokenId);

    listings[msg.sender][tokenId] = Listing({
      owner: msg.sender,
      tokenId: tokenId,
      currency: currency,
      amount: amount
    });

    emit PackListed(msg.sender, tokenId, currency, amount);
  }

  function buy(address from, uint256 tokenId, uint256 quantity) external nonReentrant {
    require(from != address(0), "invalid listing owner");

    Listing memory listing = listings[from][tokenId];
    require(listing.currency != address(0), "invalid price token");

    address creator = packToken.ownerOf(tokenId);
    uint256 totalPrice = listing.amount.mul(quantity);
    uint256 protocolCut = totalPrice.mul(protocolFeeBps).div(MAX_BPS);
    uint256 creatorCut = listing.owner == creator ? 0 : totalPrice.mul(creatorFeeBps).div(MAX_BPS);
    uint256 sellerCut = totalPrice - protocolCut - creatorCut;

    IERC20 priceToken = IERC20(listing.currency);

    priceToken.approve(address(this), sellerCut + creatorCut);

    require(priceToken.transferFrom(msg.sender, address(this), totalPrice));
    require(priceToken.transferFrom(address(this), listing.owner, sellerCut));
    if (creatorCut > 0) {
      require(priceToken.transferFrom(address(this), creator, creatorCut));
    }

    packToken.safeTransferFrom(listing.owner, msg.sender, tokenId, quantity, "");

    emit PackSold(from, msg.sender, tokenId, quantity);
  }

  fallback() external payable {}
  receive() external payable {}
}
