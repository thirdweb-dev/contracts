// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./PackERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pack is PackERC1155 {

  struct RandomnessRequest {
    address packOpener;
    uint packId;
  }

  event PackCreated(address indexed creator, uint indexed tokenId, string tokenUri, uint maxSupply);
  event PackOpened(address indexed owner, uint indexed tokenId);

  event RewardsAdded(uint indexed packId, uint[] rewardTokenIds, string[] rewardTokenUris, uint[] rewardTokenMaxSupplies);
  event RewardDistributed(address indexed receiver, uint indexed packID, uint indexed rewardTokenId); 

  /// @dev tokenId (for TokenType.Pack) => tokenIds of rewards in pack.
  mapping(uint => uint[]) public rewardsInPack;

  /// @dev tokenId => total supply of token.
  mapping(uint => uint) public circulatingSupply;

  /// @dev RNG request Id => request state `RandomnessRequest`. 
  mapping(uint => RandomnessRequest) public randomnessRequests;

  constructor(address _controlCenter) PackERC1155(_controlCenter) {}

  /// @notice Lets a creator create a pack with rewards.
  function createPack(
    string calldata tokenUri,   
    string[] calldata rewardTokenUris,
    uint[] memory rewardTokenMaxSupplies
  ) external returns (uint tokenId, uint amountMinted) {

    require(rewardTokenMaxSupplies.length == rewardTokenUris.length, "Must provide the same amount of maxSupplies and URIs.");
    require(rewardTokenUris.length > 0, "Cannot create a pack with no rewards.");

    // Get pack's `tokenId`
    tokenId = _tokenId();

    // Add rewards and get max supply of pack.
    for (uint i = 0; i < rewardTokenUris.length; i++) {
      addReward(tokenId, rewardTokenUris[i], rewardTokenMaxSupplies[i]);
      amountMinted += rewardTokenMaxSupplies[i];
    }

    // Store pack state
    tokens[tokenId] = Token({
      creator: msg.sender,
      uri: tokenUri,
      rarityUnit: amountMinted,
      maxSupply: amountMinted,
      tokenType: TokenType.Pack
    });

    circulatingSupply[tokenId] = amountMinted;

    // Mint max supply of pack token to the creator.
    _mint(msg.sender, tokenId, amountMinted, "");

    emit PackCreated(msg.sender, tokenId, tokenUri, amountMinted);
    emit RewardsAdded(tokenId, rewardsInPack[tokenId], rewardTokenUris, rewardTokenMaxSupplies);
  }

  /// @dev Stores reward token state and returns the reward's ERC1155 tokenId.
  function addReward(uint packId, string calldata tokenUri, uint maxSupply) internal {
    
    // Get `tokenId`
    uint tokenId = _tokenId();

    // Store reward token state
    tokens[tokenId] = Token({
      creator: msg.sender,
      uri: tokenUri,
      rarityUnit: maxSupply,
      maxSupply: maxSupply,
      tokenType: TokenType.Reward
    });

    rewardsInPack[packId].push(tokenId);
  }

  /// @notice Lets a pack token owner open a single pack
  function openPack(uint packId) external {
    require(balanceOf(msg.sender, packId) > 0, "Sender owns no packs of the given packId.");
    
    bool isExternalService = _rng().usingExternalService();

    if(isExternalService) {
      // Approve RNG to handle fee amount of fee token.
      (address feeToken, uint feeAmount) = _rng().getRequestFee();
      if(feeToken != address(0)) {
        require(
          IERC20(feeToken).approve(address(_rng()), feeAmount),
          "Failed to approve rng to handle fee amount of fee token."
        );
      }
      // Request external service for a random number. Store the request ID and lockBlock.
      (uint requestId,) = _rng().requestRandomNumber();

      randomnessRequests[requestId] = RandomnessRequest({
        packOpener: msg.sender,
        packId: packId
      });
    } else {
      (uint randomness,) = _rng().getRandomNumber();
      uint rewardTokenId = getRandomReward(packId, randomness);
      
      distributeReward(msg.sender, packId, rewardTokenId);
      emit RewardDistributed(msg.sender, packId, rewardTokenId);
    }

    emit PackOpened(msg.sender, packId);
  }

  /// @dev returns a random reward tokenId using `randomness` provided by Chainlink VRF.
  function getRandomReward(uint packId, uint randomness) internal returns (uint rewardTokenId) {

    uint prob = randomness % tokens[packId].rarityUnit;
    uint step = 0;

    for(uint i = 0; i < rewardsInPack[packId].length; i++) {
      uint tokenId = rewardsInPack[packId][i];
      uint rarityNumerator = tokens[tokenId].rarityUnit;

      if(prob < (rarityNumerator + step)) {
        rewardTokenId = tokenId;
        tokens[tokenId].rarityUnit -= 1;
        break;
      } else {
        step += rarityNumerator;
      }
    }

    tokens[packId].rarityUnit -= 1;
  }

  /// @dev Distributes a reward token to the pack opener.
  function distributeReward(address _receiver, uint _packId, uint _rewardId) internal {
    _burn(_receiver, _packId, 1);
    circulatingSupply[_packId] -= 1;

    _mint(_receiver, _rewardId, 1, "");
    circulatingSupply[_rewardId] += 1;
  }

  /// @dev Called by Chainlink VRF random number provider.
  function fulfillRandomness(uint requestId, uint randomness) external {
    require(msg.sender == address(_rng()), "Only the appointed RNG can fulfill random number requests.");
    
    RandomnessRequest memory request = randomnessRequests[requestId];

    uint rewardTokenId = getRandomReward(request.packId, randomness);
    distributeReward(request.packOpener, request.packId, rewardTokenId);

    delete randomnessRequests[requestId];

    emit RewardDistributed(request.packOpener, request.packId, rewardTokenId);
  }
}
