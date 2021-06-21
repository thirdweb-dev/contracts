// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PackControl.sol";
import "./interfaces/RNGInterface.sol";

contract Pack is ERC1155PresetMinterPauser {

  PackControl internal controlCenter;

  uint public currentTokenId;

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

  event TokenTransferSingle(address indexed from, address indexed to, uint tokenId, uint amount, TokenType tokenType);
  event TokenTransferBatch(address indexed from, address indexed to, uint[] tokenIds, uint[] amounts, TokenType tokenType);
  event TokenBurned(address indexed burner, uint indexed tokenId, uint amount);

  /// @notice Maps a `tokenId` to its Token state
  mapping(uint => Token) public tokens;

  /// @dev tokenId (for TokenType.Pack) => tokenIds of rewards in pack.
  mapping(uint => uint[]) public rewardsInPack;

  /// @dev tokenId => total supply of token.
  mapping(uint => uint) public circulatingSupply;

  /// @dev RNG request Id => request state `RandomnessRequest`. 
  mapping(uint => RandomnessRequest) public randomnessRequests;

  constructor(address _controlCenter) ERC1155PresetMinterPauser("") {
    controlCenter = PackControl(_controlCenter);
    grantRole(PAUSER_ROLE, _controlCenter);
  }

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

  /// @dev Called by protocol RNG when using an external random number provider.
  function fulfillRandomness(uint requestId, uint randomness) external {
    require(msg.sender == address(_rng()), "Only the appointed RNG can fulfill random number requests.");
    
    RandomnessRequest memory request = randomnessRequests[requestId];

    uint rewardTokenId = getRandomReward(request.packId, randomness);
    distributeReward(request.packOpener, request.packId, rewardTokenId);

    emit RewardDistributed(request.packOpener, request.packId, rewardTokenId);
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

  /// @dev Returns and then increments `currentTokenId`
  function _tokenId() internal returns (uint tokenId) {
    tokenId = currentTokenId;
    currentTokenId++;
  }

  function _rng() internal view returns (RNGInterface) {
    return RNGInterface(controlCenter.packRNG());
  }

  /**
   * @notice See the ERC1155 API. Returns the token URI of the token with id `tokenId`
   *
   * @param id The ERC1155 tokenId of a pack or reward token. 
   */
  function uri(uint id) public view override returns (string memory) {
    return tokens[id].uri;
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  )
    public
    override
  { 
    emit TokenTransferSingle(from, to, id, amount, tokens[id].tokenType);

    // Call OZ `safeTransferFrom` implementation
    super.safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  )
    public
    override
  {
    TokenType tokenType;

    for (uint i = 0; i < ids.length; i++) {
      uint tokenId = ids[i];

      if(i == 0) {
        tokenType = tokens[tokenId].tokenType;
        continue;
      } else if(tokens[tokenId].tokenType != tokenType) {
        revert("Can only transfer a batch of the same type of token.");
      }
    }

    emit TokenTransferBatch(from, to, ids, amounts, tokenType);
    
    // Call OZ `safeBatchTransferFrom` implementation
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}