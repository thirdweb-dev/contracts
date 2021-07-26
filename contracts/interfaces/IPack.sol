// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IPack is IERC1155MetadataURI, IERC1155Receiver {
  
  /// @dev The state of a set of packs with the same tokenId;
  struct PackInfo {
    uint packId;
    address creator;
    string uri;
    uint currentSupply;

    uint openStart;
    uint openEnd;
  }
  
  /**
   * @notice Creates packs filled with the underlying rewards provided.
   *
   * @param _packURI The media URI of the pack.
   * @param _rewardContract The address of the rewards contract.
   * @param _rewardIds The tokenIds of the rewards being packed.
   * @param _rewardAmounts The amounts of each reward to pack.
   * @param _secondsUntilOpenStart The seconds from the time of pack creation, until when the pack can be opened.
   * @param _secondsUntilOpenEnd The seconds from the time of pack creation, until after when packs can no longer be opened.
   *
   * @dev Both `_rewardIds` and `_rewardAmounts` must be ordered i.e. `_rewardAmounts[i]` amount of the reward with tokenId 
   * `_rewardIds[i]` is being packed.
   *
   * @return packId : The tokenId of the packs created.
   * @return packTotalSupply : The total supply of the packs minted.
   */
  function createPack(
    string calldata _packURI,

    address _rewardContract, 
    uint[] calldata _rewardIds, 
    uint[] calldata _rewardAmounts,

    uint _secondsUntilOpenStart,
    uint _secondsUntilOpenEnd

  ) external returns (uint packId, uint packTotalSupply);

  /**
   * @notice Lets a pack owner open a pack for an underlying reward.
   *
   * @param _packId The token ID of the pack to open.
   */
  function openPack(uint _packId) external;

  /**
   * @notice Called by the Chainlink VRF system to fulfill a randomness request.
   *
   * @param _requestId The request Id of a random number request.
   * @param _randomness The random number sent by the Chainlink VRF system.
   */
  function fulfillRandomness(uint _requestId, uint _randomness) external;

  /**
   * @notice Returns the current state of the set of packs of id `_packId`
   *
   * @param _packId The tokenId of a given set of packs.
   *
   * @return pack : The current state of the set of pack of id `_packId`
   */
  function getPackById(uint _packId) external view returns (PackInfo memory pack);

  /**
   * @notice Returns (for a given pack) the source of rewards, the tokenIds of the rewards and the amounts of each reward still packed.
   *
   * @param _packId The tokenId of a given set of packs.
   *
   * @return source : The source of the pack's underlying rewards.
   * @return tokenIds : The tokenIds of the pack's underlying rewards.
   * @return amountsPacked : The amounts of reach rewards still packed.
   */
  function getRewards(uint _packId) external view returns (address source, uint[] memory tokenIds, uint[] memory amountsPacked);

  /// @notice Returns the address of the creator of a pack.
  function creator(uint _packId) external view returns (address _creator);

  /// @notice Returns the media URI of a pack.
  function tokenURI(uint _packId) external view returns (string memory);

  /// @notice Returns the current total supply of a pack.
  function totalSupply(uint _packId) external view returns (uint _supply);
}