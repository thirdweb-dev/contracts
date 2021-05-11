pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IPack.sol';
import './Pack.sol';

contract PackMarket is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  Pack public immutable packToken;

  uint256 public constant MAX_BPS = 10000; // 100%
  uint256 public protocolFeeBps = 500; // 5%
  uint256 public creatorFeeBps = 500; // 5%

  struct Listing {
    address owner;
    uint256 tokenId;
    address priceToken;
    uint256 priceAmount;
  }

  // owner => tokenId => Listing
  mapping(address => mapping(uint256 => Listing)) public listings;

  constructor(address _packToken) {
    packToken = Pack(_packToken);
  }

  function sell(uint256 tokenId, address priceToken, uint256 priceAmount) external {
    require(packToken.isApprovedForAll(msg.sender, address(this)), "require token approval");
    require(packToken.balanceOf(msg.sender, tokenId) > 0, "require at least 1 token");

    listings[msg.sender][tokenId] = Listing({
      owner: msg.sender,
      tokenId: tokenId,
      priceToken: priceToken,
      priceAmount: priceAmount
    });
  }

  function buy(address from, uint256 tokenId, uint256 quantity) external nonReentrant {
    require(from != address(0), "invalid listing owner");

    Listing memory listing = listings[from][tokenId];
    require(listing.priceToken != address(0), "invalid price token");

    address creator = packToken.owner(tokenId);
    uint256 totalPrice = listing.priceAmount.mul(quantity);
    uint256 protocolCut = totalPrice.mul(protocolFeeBps).div(MAX_BPS);
    uint256 creatorCut = listing.owner == creator ? 0 : totalPrice.mul(creatorFeeBps).div(MAX_BPS);
    uint256 sellerCut = totalPrice - protocolCut - creatorCut;

    IERC20 priceToken = IERC20(listing.priceToken);
    priceToken.transferFrom(msg.sender, address(this), totalPrice);

    priceToken.approve(address(this), sellerCut + creatorCut);
    priceToken.transferFrom(address(this), listing.owner, sellerCut);
    if (creatorCut > 0) {
      priceToken.transferFrom(address(this), creator, creatorCut);
    }

    packToken.safeTransferFrom(listing.owner, msg.sender, tokenId, quantity, "");
  }
}
