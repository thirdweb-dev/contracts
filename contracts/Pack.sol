// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./interfaces/IPackEvent.sol";

contract Pack is ERC1155, Ownable, IPackEvent {
  using SafeMath for uint256;

  enum TokenType {
    Pack,
    Reward
  }

  struct Token {
    address creator;
    string uri;
    uint256 currentSupply;
    uint256 maxSupply;
    TokenType tokenType;
  }

  /// @dev Orders reward tokens from lowest rarityNumerator to highest rarityNumerator.
  struct RewardDistribution {
    uint numOfRewards;

    // Index => rarity numerator
    mapping(uint => uint) rarityNumerator;
    // Index => TokenId
    mapping(uint => uint) indexToTokenId;
    // TokenId => Index
    mapping(uint => uint) tokenIdToIndex;
  }

  struct PackState {
    address creator;
    bool isRewardLocked;
    uint256 numRewardOnOpen;
    uint256 rarityDenominator;
    uint256[] rewardTokenIds;
  }

  uint256 private _currentTokenId = 0;
  uint256 private _seed;

  mapping(uint256 => Token) public tokens;
  mapping(uint256 => PackState) public packs;
  mapping(uint256 => RewardDistribution) public rewardDistribution;

  constructor() ERC1155("") {}
  
  /**
  * @notice Lets a creator create a Pack.
  * @dev Mints an ERC1155 pack token with URI `tokenUri` and total supply `maxSupply`
  *
  * @param tokenUri The URI for the pack cover of the pack being created.
  * @param maxSupply The total ERC1155 token supply of the pack being created.
   */
  function createPack(string memory tokenUri, uint256 maxSupply) external returns (uint256 tokenId) {
    tokenId = _currentTokenId;
    _currentTokenId += 1;

    tokens[tokenId] = Token({
      creator: msg.sender,
      uri: tokenUri,
      currentSupply: 0,
      maxSupply: maxSupply,
      tokenType: TokenType.Pack
    });

    PackState storage pack = packs[tokenId];
    pack.isRewardLocked = false;
    pack.creator = msg.sender;
    pack.numRewardOnOpen = 1;
    pack.rarityDenominator = 0;

    _mintSupplyChecked(msg.sender, tokenId, maxSupply);

    emit PackCreated(msg.sender, tokenId, tokenUri, maxSupply);
  }

  /**
   * @notice Lets a creator add rewards to their pack.
   * @dev Saves ERC1155 Reward token information in a struct, without minting the token.
   *
   * @param packId The ERC1155 tokenId of a pack token.
   * @param tokenMaxSupplies The total ERC1155 token supply for each reward token added to the pack.
   * @param tokenUris The URIs for each reward token added to the pack.
   */
  function addRewards(uint256 packId, uint256[] memory tokenMaxSupplies, string[] memory tokenUris) external {
    require(packs[packId].creator == msg.sender, "not the pack owner");
    require(!packs[packId].isRewardLocked, "reward is locked");
    require(tokenMaxSupplies.length == tokenUris.length, "arrays must be same length");

    uint256 denominatorToAdd = 0;
    uint256[] memory newRewardTokenIds = new uint256[](tokenUris.length);
    for (uint256 i = 0; i < tokenUris.length; i++) {
      string memory tokenUri = tokenUris[i];

      uint256 tokenId = _currentTokenId;
      _currentTokenId += 1;

      tokens[tokenId] = Token({
        creator: msg.sender,
        uri: tokenUri,
        currentSupply: 0,
        maxSupply: tokenMaxSupplies[i],
        tokenType: TokenType.Reward
      });
      
      packs[packId].rewardTokenIds.push(tokenId);      
      denominatorToAdd += tokenMaxSupplies[i];

      newRewardTokenIds[i] = tokenId;
    }

    packs[packId].rarityDenominator += denominatorToAdd;

    emit PackRewardsAdded(msg.sender, packId, newRewardTokenIds, tokenUris);
  }

  /**
   * @notice Lets a pack creator lock the rewards for the pack. The rewards in a pack cannot be changed once the 
   *         rewards are locked
   *
   * @param packId The ERC1155 tokenId of the pack whose rewawrds are to be locked.
   */
  function lockReward(uint256 packId) public {
    // NOTE: there's no way to unlock.
    require(packs[packId].creator == msg.sender, "not the pack owner");
    packs[packId].isRewardLocked = true;

    uint[] memory rewardTokenIds = packs[packId].rewardTokenIds;

    for(uint i = 0; i < rewardTokenIds.length; i++) {
      uint tokenId = rewardTokenIds[i];
      uint maxSupply = tokens[tokenId].maxSupply;

      addRewardToDistribution(packId, tokenId, maxSupply);
    }

    emit PackRewardsLocked(msg.sender, packId);
  }

  /// @dev Adds a reward token to the packs `RewardDistribution` based on the reward's rarityNumerator.
  function addRewardToDistribution(uint packId, uint rewardTokenId, uint maxSupply) internal {
    RewardDistribution storage distribution = rewardDistribution[packId];
    uint nextIndex = distribution.numOfRewards;
    uint targetIndex = 0;

    if(nextIndex == 0) {
      distribution.rarityNumerator[targetIndex] = maxSupply;
      distribution.indexToTokenId[targetIndex] = rewardTokenId;
      distribution.tokenIdToIndex[rewardTokenId] = targetIndex;

      distribution.numOfRewards += 1;
      return;
    }

    uint checkpoint = 0;

    while(checkpoint <= nextIndex) {
      if (distribution.rarityNumerator[checkpoint] >= maxSupply) {
        targetIndex = checkpoint;
      } else {
        checkpoint++;
      }
    }

    for(uint i = nextIndex; i > checkpoint; i--) {
      distribution.rarityNumerator[i] = distribution.rarityNumerator[i-1];
      distribution.indexToTokenId[i] = distribution.indexToTokenId[i-1];

      uint tokenId = distribution.indexToTokenId[i];
      distribution.tokenIdToIndex[tokenId] += 1;
    }

    distribution.numOfRewards += 1;
    distribution.rarityNumerator[targetIndex] = maxSupply;
    distribution.indexToTokenId[targetIndex] = rewardTokenId;
    distribution.tokenIdToIndex[rewardTokenId] = targetIndex;
  }

  /**
  * @notice Lets a pack token owner open a single pack
  * @dev Mints an ERC1155 Reward token to `msg.sender`
  *
  * @param packId The ERC1155 tokenId of the pack token being opened.
   */
  function openPack(uint256 packId) external {
    require(balanceOf(msg.sender, packId) > 0, "insufficient pack");

    uint256 numRewarded = 1; // This is the number of the specific token rewarded
    uint256 rewardedTokenId = getRandomReward(packId);

    _burn(msg.sender, packId, 1); // note: does not reduce the supply
    _mintSupplyChecked(msg.sender, rewardedTokenId, numRewarded);

    uint256[] memory rewardedTokenIds = new uint256[](1);
    rewardedTokenIds[0] = rewardedTokenId;

    emit PackOpened(msg.sender, packId, rewardedTokenIds);
  }

  /// @dev returns a random reward tokenId, based on the pack's rarityDenominator and the rarityNumerator of each of the pack's rewards.
  function getRandomReward(uint packId) internal returns (uint rewardTokenId) {
    PackState memory pack = packs[packId];
    require(pack.rewardTokenIds.length > 0, "no rewards available");
    require(pack.isRewardLocked, "rewards not locked yet");

    // Large number `_random()` % rarityDenominator
    uint256 prob = _random().mod(pack.rarityDenominator);

    uint start = 0;
    uint end = rewardDistribution[packId].numOfRewards;

    uint step = 0;

    for(uint i = start; i < end; i++) {
      uint rarityNumerator = rewardDistribution[packId].rarityNumerator[i];

      if(prob < (rarityNumerator + step)) {
        rewardTokenId = rewardDistribution[packId].indexToTokenId[i];
        rewardDistribution[packId].rarityNumerator[rewardTokenId] -= 1;
        break;
      } else {
        step += rarityNumerator;
        start += 1;
      }
    }

    pack.rarityDenominator -= 1;
    adjustRewardDistribution(packId, rewardTokenId, rewardDistribution[packId].rarityNumerator[rewardTokenId]);
  }

  /// @notice Returns a (non-pseudo) random number.
  function _random() private returns (uint256) {
    // TODO: NOT SAFE.
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _seed)));
    _seed = randomNumber;
    return randomNumber;
  }

  /// @dev Adjusts the pack's `RewardDistribution` upon change in a reward token's rarityNumerator.
  function adjustRewardDistribution(uint packId, uint rewardTokenId, uint rarityNumerator) internal {
    RewardDistribution storage distribution = rewardDistribution[packId];

    uint tokenIndex = distribution.tokenIdToIndex[rewardTokenId];
    uint start = tokenIndex - 1;

    while(distribution.rarityNumerator[start] > rarityNumerator) {
      start -= 1;
    }

    if(start != (tokenIndex - 1)) {
      uint newIndex = start + 1;

      for(uint i = (newIndex + 1); i < tokenIndex; i ++) {
        distribution.rarityNumerator[i+1] = distribution.rarityNumerator[i];
        distribution.indexToTokenId[i+1] = distribution.indexToTokenId[i];

        uint tokenId = distribution.indexToTokenId[i];
        distribution.tokenIdToIndex[tokenId] += 1;
      }

      distribution.rarityNumerator[newIndex] = rarityNumerator;
      distribution.tokenIdToIndex[rewardTokenId] = newIndex;
      distribution.indexToTokenId[newIndex] = rewardTokenId;
    }
  }

  function _mintSupplyChecked(address account, uint256 id, uint256 amount) private {
    uint256 currentSupply = tokens[id].currentSupply;
    uint256 maxSupply = tokens[id].maxSupply;
    require(currentSupply + amount <= maxSupply, "not enough supply");

    tokens[id].currentSupply = currentSupply + amount;
    _mint(account, id, amount, "");
  }

  /**
   * @notice See the ERC1155 API. Returns the token URI of the token with id `tokenId`
   *
   * @param id The ERC1155 tokenId of a pack or reward token. 
   */
  function uri(uint256 id) public view override returns (string memory) {
    return tokens[id].uri;
  }

  /**
   * @notice Called by `PackMarket.sol` to check if the token with id `tokenId` is eligible for sale.
   * 
   * @param tokenId The ERC1155 tokenId of a pack or reward token.
   */
  function isEligibleForSale(uint256 tokenId) public view returns (bool) {
    if (tokens[tokenId].tokenType == TokenType.Pack) {
      return packs[tokenId].isRewardLocked;
    } else if (tokens[tokenId].tokenType == TokenType.Reward && _currentTokenId > tokenId) {
      return true;
    }

    return false;
  }

  // ========== Transfer functions ==========

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  )
    public
    virtual
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
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    public
    virtual
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
