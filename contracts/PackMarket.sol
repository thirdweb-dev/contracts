pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IPack.sol';
import './Pack.sol';

contract PackMarket is Ownable {
  using SafeMath for uint256;

  Pack public immutable packToken;

  struct Price {
    address token;
    uint256 amount;
  }

  struct Listing {
    uint256 packId;
    bool sale;
    Price price;
  }

  // packId => Listings
  mapping(uint256 => Listing) public listings;

  constructor(address _packToken) {
    packToken = Pack(_packToken);
  }

  function sell(uint256 packId, uint256 price) external {
    require(packToken.owner(packId) == msg.sender, "only owner can sell their pack");
    listings[packId].sale = true;
  }

  function buy(uint256 packId, uint256 quantity) external {
    address packOwner = packToken.owner(packId);
    require(msg.sender != packOwner, "only cannot buy their own pack");

    Listing memory listing = listings[packId];
    require(listing.sale == true, "pack is not on sale");

    uint256 price = listing.price.amount.mul(quantity);
    address from = msg.sender;
    address to = address(this);
    //IERC20(listing.price.token).transferFrom(from, to, price);
    packToken.safeTransferFrom(packOwner, msg.sender, packId, quantity, "");
  }
}
