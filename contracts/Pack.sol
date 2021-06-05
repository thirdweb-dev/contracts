
// ██████╗░░█████╗░░█████╗░██╗░░██╗
// ██╔══██╗██╔══██╗██╔══██╗██║░██╔╝
// ██████╔╝███████║██║░░╚═╝█████═╝░
// ██╔═══╝░██╔══██║██║░░██╗██╔═██╗░
// ██║░░░░░██║░░██║╚█████╔╝██║░╚██╗
// ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./interfaces/IPackEvent.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

contract Pack is ERC1155, Ownable, IPackEvent, VRFConsumerBase {
  using SafeMath for uint;

  uint public _currentTokenId = 0;

  bytes32 internal keyHash;
  uint private _seed;
  uint internal chainlinkFee = 0.1 ether;

  enum TokenType { Pack, Reward }

  struct Token {
    address creator;
    string uri;
    uint rarityUnit;
    uint maxSupply;

    TokenType tokenType;
  }

  struct RandomnessRequest {
    uint packId;
    address packOpener;
  }

  // tokenId => Token state 
  mapping(uint => Token) public tokens;

  // tokenId (for TokenType.Pack) => tokenIds of rewards in pack.
  mapping(uint => uint[]) public rewardsInPack;

  // tokenId => amount of tokens minted.
  mapping(uint => uint) public circulatingSupply;

  // Chainlink VRF requestId => tokenId (for TokenType.Pack) and request-er address.
  mapping(bytes32 => RandomnessRequest) public randomnessRequests;

  constructor(
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash
  ) VRFConsumerBase(_vrfCoordinator, _linkToken) ERC1155("") {
    keyHash = _keyHash;
  }
  
  /**
  * @notice Lets a creator create a Pack.
  * @dev Mints an ERC1155 pack token with URI `tokenUri` and total supply `maxSupply`
  *
  * @param tokenUri The URI for the pack cover of the pack being created.
  * @param rewardTokenMaxSupplies The total ERC1155 token supply for each reward token added to the pack.
  * @param rewardTokenUris The URIs for each reward token added to the pack.
   */
  function createPack(
    string calldata tokenUri,   
    string[] calldata rewardTokenUris,
    uint[] memory rewardTokenMaxSupplies
  ) external returns (uint tokenId) {

    require(rewardTokenMaxSupplies.length == rewardTokenUris.length, "Must provide the same amount of maxSupplies and URIs.");
    require(rewardTokenUris.length > 0, "Cannot create a pack with no rewards.");

    // Get `tokenId`
    tokenId = _currentTokenId;
    _currentTokenId += 1;

    // Get pack state.
    uint packMaxSupply = 0;
    uint[] memory rewardTokenIds = new uint[](rewardTokenUris.length);

    for (uint i = 0; i < rewardTokenUris.length; i++) {
      uint rewardTokenId = addReward(rewardTokenUris[i], rewardTokenMaxSupplies[i]);

      rewardTokenIds[i] = rewardTokenId;
      packMaxSupply += rewardTokenMaxSupplies[i];
    }

    // Store pack token state
    tokens[tokenId] = Token({
      creator: msg.sender,
      uri: tokenUri,
      rarityUnit: packMaxSupply,
      maxSupply: packMaxSupply,
      tokenType: TokenType.Pack
    });

    rewardsInPack[tokenId] = rewardTokenIds;
    circulatingSupply[tokenId] = packMaxSupply;

    // Mint `packMaxSupply` amount of pack token to the creator.
    _mint(msg.sender, tokenId, packMaxSupply, "");

    emit PackCreated(msg.sender, tokenId, tokenUri, packMaxSupply);
    emit RewardsAdded(msg.sender, tokenId, rewardTokenIds, rewardTokenUris, rewardTokenMaxSupplies);
  }

  /// @dev Stores reward token state and returns the reward's ERC1155 tokenId.
  function addReward(string calldata tokenUri, uint maxSupply) internal returns (uint tokenId) {
    
    // Get `tokenId`
    tokenId = _currentTokenId;
    _currentTokenId += 1;

    // Store reward token state
    tokens[tokenId] = Token({
      creator: msg.sender,
      uri: tokenUri,
      rarityUnit: maxSupply,
      maxSupply: maxSupply,
      tokenType: TokenType.Reward
    });
  }

  /**
  * @notice Lets a pack token owner open a single pack
  * @dev Mints an ERC1155 Reward token to `msg.sender`
  *
  * @param packId The ERC1155 tokenId of the pack token being opened.
   */
  function openPack(uint packId) external returns (bytes32 requestId) {
    require(balanceOf(msg.sender, packId) > 0, "Sender owns no packs of the given packId.");

    // Generate `seed` from user address and previous contract seed. Set generated `seed` as `_seed`.
    uint seed = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _seed)));
    _seed = seed;

    // Request Chainlink VRF for a random number. Store the request ID.
    requestId = requestRandomNumber(keyHash, chainlinkFee, seed);
    randomnessRequests[requestId] = RandomnessRequest({
      packId: packId,
      packOpener: msg.sender
    });

    emit PackOpened(msg.sender, packId);
  }

  /// @dev returns a random reward tokenId using `randomness` provided by Chainlink VRF.
  function getRandomReward(uint packId, uint randomness) internal returns (uint rewardTokenId) {
    require(rewardsInPack[packId].length > 0, "The pack with the given packId contains no rewards.");

    uint prob = randomness.mod(tokens[packId].rarityUnit);
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

  /// @dev Sends a random number request to the Chainlink VRF system.
  function requestRandomNumber(bytes32 _keyHash, uint _fee, uint _randomnessSeed) internal returns (bytes32 requestId) {
    requestId = requestRandomness(_keyHash, _fee, _randomnessSeed);
  }

  /// @dev Called by Chainlink VRF random number provider.
  function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
    require(randomnessRequests[requestId].packOpener != address(0), "The requestId is invalid.");

    RandomnessRequest memory request = randomnessRequests[requestId];

    uint rewardTokenId = getRandomReward(request.packId, randomness);

    _burn(request.packOpener, request.packId, 1);
    circulatingSupply[request.packId] -= 1;

    _mint(request.packOpener, rewardTokenId, 1, "");
    circulatingSupply[rewardTokenId] += 1;

    delete randomnessRequests[requestId];

    emit RewardDistributed(request.packOpener, request.packId, rewardTokenId);
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
    // Emit custom transfer event to correctly update the contract's subgraph.
    if(tokens[id].tokenType == TokenType.Pack) {
      emit TransferSinglePack(from, to, id, amount);

    } else if (tokens[id].tokenType == TokenType.Reward) {
      emit TransferSingleReward(from, to, id, amount);

    } else {
      revert("Every token is either a Pack or a Reward.");
    }

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
    bool isPack = true;
    TokenType prev = TokenType.Pack;

    for (uint i = 0; i < ids.length; i++) {

      uint tokenId = ids[i];

      if(tokens[tokenId].tokenType != TokenType.Pack) {
        isPack = false;
        prev = TokenType.Reward;
      }

      if(i != 0 && tokens[tokenId].tokenType != prev) {
        revert("Can only transfer batch of the same type of token.");
      }
    }

    // Emit custom transfer event to correctly update the contract's subgraph.
    if(isPack) {
      emit TransferBatchPacks(from, to, ids, amounts);
    } else {
      emit TransferBatchRewards(from, to, ids, amounts);
    }
    
    // Call OZ `safeBatchTransferFrom` implementation
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

}
