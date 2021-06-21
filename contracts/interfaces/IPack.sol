// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// @notice Provides the interface for Pack Protocol's primary ERC1155 contract.
interface IPack {

  /**
  * @notice Lets a creator create a pack with rewards.
  * @dev Mints an ERC1155 pack token with URI `tokenUri` and total supply `maxSupply`
  *
  * @param tokenUri The URI for the pack cover of the pack being created.
  * @param rewardTokenMaxSupplies The total ERC1155 token supply for each reward token added to the pack.
  * @param rewardTokenUris The URIs for each reward token added to the pack.
  **/
  function createPack(
    string calldata tokenUri,   
    string[] calldata rewardTokenUris,
    uint[] memory rewardTokenMaxSupplies
  ) external returns (uint tokenId);

  /**
  * @notice Lets a pack token owner open a single pack
  * @dev Mints an ERC1155 Reward token to `msg.sender`
  *
  * @param packId The ERC1155 tokenId of the pack token being opened.
  **/
  function openPack(uint packId) external returns (uint requestId)
}