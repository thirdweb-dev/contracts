// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IMarket is IERC1155Receiver {

  /// @notice The state of a particular listing of tokens.
  struct Listing {
    address seller;

    address assetContract;
    uint tokenId;

    uint quantity;
    address currency;
    uint pricePerToken;
  }

  /// @notice The window within which a particular listing is active.
  struct SaleWindow {
    uint start;
    uint end;
  }
  
  /**
   * @notice Lets a pack or reward owner list their tokens for sale.
   *
   * @param _assetContract The ERC 1155 token contract of the tokens to list for sale.
   * @param _tokenId The ERC 1155 token ID of the tokens to list for sale.
   * @param _currency The currency accepted by the listing.
   * @param _pricePerToken The price per token for the tokens to list for sale.
   * @param _quantity The quantity of tokens to list for sale.
   * @param _secondsUntilStart The seconds from the time of listing, until when people can buy from the listing.
   * @param _secondsUntilEnd The seconds from the time of listing, until after when people can no longer buy from the listing.
   */
  function list(
    address _assetContract, 
    uint _tokenId,

    address _currency,
    uint _pricePerToken,
    uint _quantity,

    uint _secondsUntilStart,
    uint _secondsUntilEnd
  ) external;

  /**
   * @notice Lets a person buy a given quantity of tokens from a listing.
   *
   * @param _seller The seller who is selling the tokens.
   * @param _listingId The unique ID of the listing of tokens to buy from.
   * @param _quantity The quantity of tokens to buy from the listing. 
   */
  function buy(address _seller, uint _listingId, uint _quantity) external payable;

  /**
   * @notice Returns the total number of listings of a seller.
   *
   * @param _seller The seller whose total listing count is to be retrieved.
   *
   * @return numOfListings : The total number of listings of the seller.
   */
  function getTotalNumOfListings(address _seller) external view returns (uint numOfListings);

  /**
   * @notice Returns the state of a given listing.
   *
   * @param _seller The seller of the listing.
   * @param _listingId The unique listing ID of the listing.
   *
   * @return listing : The state of the listing.
   */
  function getListing(address _seller, uint _listingId) external view returns (Listing memory listing);

  /**
   * @notice Returns the window withing which a particular listing is active.
   *
   * @param _seller The seller of the listing.
   * @param _listingId The unique listing ID of the listing.
   *
   * @return start : The time after which the listing is active.
   * @return end : The time after which the listing is inactive.
   */
  function getSaleWindow(address _seller, uint _listingId) external view returns (uint start, uint end);
}