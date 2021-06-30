// SPDX-License-Identifier: GPL-3.0 

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PackControl.sol";
import "./PackERC1155.sol";

contract PackHandler {

  PackControl internal controlCenter;
  string public constant PACK_ERC1155_MODULE_NAME = "PACK_ERC1155";

  enum TokenType { Pack, Reward }

  struct RewardsInPack {
    uint[] rarityNumerators;
    string[] rewardURIs;
  }

  struct RandomnessRequest {
    address packOpener;
    uint packId;
  }

  event PackCreated(address indexed creator, uint indexed tokenId, string tokenUri, string[] rewardTokenUris, uint[] rewardTokenMaxSupplies);
  event PackOpened(address indexed opener, uint indexed packId, uint indexed rewardTokenId);

  /// @dev tokenId (for TokenType.Pack) => tokenIds of rewards in pack.
  mapping(uint => RewardsInPack) rewardsInPack;

  /// @dev RNG request Id => request state `RandomnessRequest`. 
  mapping(uint => RandomnessRequest) public randomnessRequests;

  constructor(address _controlCenter) {
    controlCenter = PackControl(_controlCenter);
  }

  /// @notice Lets a creator create a pack with rewards.
  function createPack(
    string calldata tokenUri,   
    string[] calldata rewardTokenUris,
    uint[] memory rewardTokenMaxSupplies
  ) external returns (uint tokenId) {

    require(rewardTokenMaxSupplies.length == rewardTokenUris.length, "Must provide the same amount of maxSupplies and URIs.");
    require(rewardTokenUris.length > 0, "Cannot create a pack with no rewards.");

    // Get pack's `tokenId`
    tokenId = packERC1155()._tokenId(rewardTokenUris.length);

    // Store reward state.
    rewardsInPack[tokenId] = RewardsInPack({
      rarityNumerators: rewardTokenMaxSupplies,
      rewardURIs: rewardTokenUris
    });

    // Mint max supply of pack token to the creator.
    packERC1155().mintToken(msg.sender, msg.sender, tokenId, sumArr(rewardTokenMaxSupplies), tokenUri, uint(TokenType.Pack));

    emit PackCreated(msg.sender, tokenId, tokenUri, rewardTokenUris, rewardTokenMaxSupplies);
  }

  /// @notice Lets a pack token owner open a single pack
  function openPack(uint packId) external {
    require(packERC1155().balanceOf(msg.sender, packId) > 0, "Sender owns no packs of the given packId.");

    if(packERC1155()._rng().usingExternalService()) {
      // Approve RNG to handle fee amount of fee token.
      (address feeToken, uint feeAmount) = packERC1155()._rng().getRequestFee();
      if(feeToken != address(0)) {
        require(
          IERC20(feeToken).approve(address(packERC1155()._rng()), feeAmount),
          "Failed to approve rng to handle fee amount of fee token."
        );
      }
      // Request external service for a random number. Store the request ID and lockBlock.
      (uint requestId,) = packERC1155()._rng().requestRandomNumber();

      randomnessRequests[requestId] = RandomnessRequest({
        packOpener: msg.sender,
        packId: packId
      });
    } else {
      (uint randomness,) = packERC1155()._rng().getRandomNumber(block.number);
      (uint rewardTokenId, string memory rewardURI) = getRandomReward(packId, randomness);
      distributeReward(msg.sender, packId, rewardTokenId, rewardURI);
      
      emit PackOpened(msg.sender, packId, rewardTokenId);
    }
  }

  /// @dev Called by protocol RNG when using an external random number provider.
  function fulfillRandomness(uint requestId, uint randomness) external {
    require(msg.sender == address(packERC1155()._rng()), "Only the appointed RNG can fulfill random number requests.");
    
    RandomnessRequest memory request = randomnessRequests[requestId];

    (uint rewardTokenId, string memory rewardURI) = getRandomReward(request.packId, randomness);
    distributeReward(request.packOpener, request.packId, rewardTokenId, rewardURI);

    emit PackOpened(request.packOpener, request.packId, rewardTokenId);
  }

  /// @dev returns a random reward tokenId using `randomness` provided by Chainlink VRF.
  function getRandomReward(uint packId, uint randomness) internal returns (uint rewardTokenId, string memory rewardURI) {

    uint prob = randomness % sumArr(rewardsInPack[packId].rarityNumerators);
    uint step = 0;

    for(uint i = 1; i <= rewardsInPack[packId].rewardURIs.length; i++) {
      if(prob < (rewardsInPack[packId].rarityNumerators[i-1] + step)) {
        rewardTokenId = packId + i;
        rewardURI = rewardsInPack[packId].rewardURIs[i-1];
        rewardsInPack[packId].rarityNumerators[i-1] -= 1;
        break;
      } else {
        step += rewardsInPack[packId].rarityNumerators[i-1];
      }
    }
  }

  /// @dev Distributes a reward token to the pack opener.
  function distributeReward(address _receiver, uint _packId, uint _rewardId, string memory rewardURI) internal {
    // Burn the opened pack.
    packERC1155().burn(_receiver, _packId, 1);

    // Get pack creator
    (address creator,,,) = packERC1155().tokens(_packId);

    // Mint the appropriate reward token.
    packERC1155().mintToken(creator, _receiver, _rewardId, 1, rewardURI, uint(TokenType.Reward));
  }

  /// @dev Returns the PackERC1155 contract.
  function packERC1155() internal view returns (PackERC1155) {
    return PackERC1155(
      controlCenter.getModule(PACK_ERC1155_MODULE_NAME)
    );
  }

  /// @dev Returns the sum of all elements in the array
  function sumArr(uint[] memory arr) internal pure returns (uint sum) {
    for(uint i = 0; i < arr.length; i++) {
      sum += arr[i];
    }
  }
}