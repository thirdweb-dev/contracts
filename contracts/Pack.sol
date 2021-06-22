// SPDX-License-Identifier: GPL-3.0 

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PackERC1155.sol";

contract Pack is IERC1155Receiver {

  PackERC1155 internal packERC1155;

  enum TokenType { Pack, Reward }

  struct Token {
    address creator;
    string uri;
    uint rarityUnit;
    uint maxSupply;

    TokenType tokenType;
  }

  struct RandomnessRequest {
    address packOpener;
    uint packId;
  }

  event PackCreated(address indexed creator, uint indexed tokenId, string tokenUri, uint maxSupply);
  event PackOpened(address indexed owner, uint indexed tokenId);

  event RewardsAdded(uint indexed packId, uint[] rewardTokenIds, string[] rewardTokenUris, uint[] rewardTokenMaxSupplies);
  event RewardDistributed(address indexed receiver, uint indexed packID, uint indexed rewardTokenId);

  /// @notice Maps a `tokenId` to its Token state.
  mapping(uint => Token) public tokens;

  /// @dev tokenId (for TokenType.Pack) => tokenIds of rewards in pack.
  mapping(uint => uint[]) public rewardsInPack;

  /// @dev RNG request Id => request state `RandomnessRequest`. 
  mapping(uint => RandomnessRequest) public randomnessRequests;

  constructor(address _packERC1155) {
    packERC1155 = PackERC1155(_packERC1155);
  }

  /// @notice Lets a creator create a pack with rewards.
  function createPack(
    string calldata tokenUri,   
    string[] calldata rewardTokenUris,
    uint[] memory rewardTokenMaxSupplies
  ) external returns (uint tokenId, uint packsMinted) {

    require(rewardTokenMaxSupplies.length == rewardTokenUris.length, "Must provide the same amount of maxSupplies and URIs.");
    require(rewardTokenUris.length > 0, "Cannot create a pack with no rewards.");

    // Get pack's `tokenId`
    tokenId = packERC1155._tokenId();

    // Add rewards and get max supply of pack.
    for (uint i = 0; i < rewardTokenUris.length; i++) {
      addReward(tokenId, rewardTokenUris[i], rewardTokenMaxSupplies[i]);
      packsMinted += rewardTokenMaxSupplies[i];
    }

    // Store pack state
    tokens[tokenId] = Token({
      creator: msg.sender,
      uri: tokenUri,
      rarityUnit: packsMinted,
      maxSupply: packsMinted,
      tokenType: TokenType.Pack
    });

    // Mint max supply of pack token to the creator.
    packERC1155.mintTokens(msg.sender, tokenId, packsMinted, tokenUri, uint(TokenType.Pack));

    emit PackCreated(msg.sender, tokenId, tokenUri, packsMinted);
    emit RewardsAdded(tokenId, rewardsInPack[tokenId], rewardTokenUris, rewardTokenMaxSupplies);
  }

  /// @notice Lets a pack token owner open a single pack
  function openPack(uint packId) external {
    require(packERC1155.balanceOf(msg.sender, packId) > 0, "Sender owns no packs of the given packId.");
    
    bool isExternalService = packERC1155._rng().usingExternalService();

    if(isExternalService) {
      // Approve RNG to handle fee amount of fee token.
      (address feeToken, uint feeAmount) = packERC1155._rng().getRequestFee();
      if(feeToken != address(0)) {
        require(
          IERC20(feeToken).approve(address(packERC1155._rng()), feeAmount),
          "Failed to approve rng to handle fee amount of fee token."
        );
      }
      // Request external service for a random number. Store the request ID and lockBlock.
      (uint requestId,) = packERC1155._rng().requestRandomNumber();

      randomnessRequests[requestId] = RandomnessRequest({
        packOpener: msg.sender,
        packId: packId
      });
    } else {
      (uint randomness,) = packERC1155._rng().getRandomNumber();
      uint rewardTokenId = getRandomReward(packId, randomness);
      distributeReward(msg.sender, packId, rewardTokenId);
      emit RewardDistributed(msg.sender, packId, rewardTokenId);
    }

    emit PackOpened(msg.sender, packId);
  }

  /// @dev Called by protocol RNG when using an external random number provider.
  function fulfillRandomness(uint requestId, uint randomness) external {
    require(msg.sender == address(packERC1155._rng()), "Only the appointed RNG can fulfill random number requests.");
    
    RandomnessRequest memory request = randomnessRequests[requestId];

    uint rewardTokenId = getRandomReward(request.packId, randomness);
    distributeReward(request.packOpener, request.packId, rewardTokenId);

    emit RewardDistributed(request.packOpener, request.packId, rewardTokenId);
  }

  /// @dev Stores reward token state and returns the reward's ERC1155 tokenId.
  function addReward(uint packId, string calldata tokenUri, uint maxSupply) internal {
    
    // Get `tokenId`
    uint tokenId = packERC1155._tokenId();

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
    // Burn the opened pack.
    packERC1155.burn(_receiver, _packId, 1);

    // Mint the appropriate reward token.
    packERC1155.mintTokens(_receiver, _rewardId, 1, tokens[_rewardId].uri, uint(tokens[_rewardId].tokenType));
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