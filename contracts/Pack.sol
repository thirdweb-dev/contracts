pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./interfaces/IPackEvent.sol";

contract Pack is ERC1155, Ownable, IPackEvent {
  using SafeMath for uint256;

  uint256 private constant REWARD_RARITY_DENOMINATOR = 10000;

  enum TokenType {
    Pack,
    Reward
  }

  struct Token {
    string uri;
    uint256 currentSupply;
    uint256 maxSupply;
    TokenType tokenType;
  }

  struct Reward {
    uint256 rarityNumerator;
  }

  struct PackState {
    address owner;
    bool isRewardLocked;
    uint256 numRewardOnOpen;
    uint256 rarityDenominator;
    uint256[] rewardTokenIds;
  }

  uint256 private _currentTokenId = 0;
  uint256 private _seed;

  mapping(uint256 => Token) public tokens;
  mapping(uint256 => PackState) public packs;
  mapping(uint256 => Reward) public rewards;

  constructor() ERC1155("") {
  }

  function createPack(string memory tokenUri, uint256 maxSupply) external returns (uint256 tokenId) {
    tokenId = _currentTokenId;
    _currentTokenId += 1;

    tokens[tokenId] = Token({
      uri: tokenUri,
      currentSupply: 0,
      maxSupply: maxSupply,
      tokenType: TokenType.Pack
    });

    PackState storage pack = packs[tokenId];
    pack.isRewardLocked = false;
    pack.owner = msg.sender;
    pack.numRewardOnOpen = 1;
    pack.rarityDenominator = REWARD_RARITY_DENOMINATOR;

    _mintSupplyChecked(msg.sender, tokenId, maxSupply);

    emit PackCreated(msg.sender, tokenId, tokenUri, maxSupply);
  }

  function openPack(uint256 packId) external {
    require(balanceOf(msg.sender, packId) > 0, "insufficient pack");

    PackState memory pack = packs[packId];
    require(pack.rewardTokenIds.length > 0, "no rewards available");
    require(pack.isRewardLocked, "rewards not locked yet");

    uint256 prob = _random().mod(pack.rarityDenominator);
    uint256 index = prob.mod(pack.rewardTokenIds.length);
    uint256 rewardedTokenId = pack.rewardTokenIds[index];

    _burn(msg.sender, packId, 1); // note: does not reduce the supply
    _mintSupplyChecked(msg.sender, rewardedTokenId, 1);

    uint256[] memory rewardedTokenIds = new uint256[](1);
    rewardedTokenIds[0] = rewardedTokenId;
    emit PackOpened(msg.sender, packId, rewardedTokenIds);
  }

  function addRewards(uint256 packId, uint256[] memory tokenMaxSupplies, string[] memory tokenUris) external {
    require(packs[packId].owner == msg.sender, "not the pack owner");
    require(!packs[packId].isRewardLocked, "reward is locked");

    uint256[] memory newRewardTokenIds = new uint256[](tokenUris.length);
    for (uint256 i = 0; i < tokenUris.length; i++) {
      string memory tokenUri = tokenUris[i];

      uint256 tokenId = _currentTokenId;
      _currentTokenId += 1;

      tokens[tokenId] = Token({
        uri: tokenUri,
        currentSupply: 0,
        maxSupply: tokenMaxSupplies[i],
        tokenType: TokenType.Reward
      });
      packs[packId].rewardTokenIds.push(tokenId);
      rewards[tokenId].rarityNumerator = 0;
      newRewardTokenIds[i] = tokenId;
    }

    emit PackRewardsAdded(msg.sender, packId, newRewardTokenIds);
  }

  function lockReward(uint256 packId) public {
    // NOTE: there's no way to unlock.
    require(packs[packId].owner == msg.sender, "not the pack owner");
    packs[packId].isRewardLocked = true;

    emit PackRewardsLocked(msg.sender, packId);
  }

  function uri(uint256 id) public view override returns (string memory) {
    return tokens[id].uri;
  }

  function ownerOf(uint256 id) public view returns (address) {
    return packs[id].owner;
  }

  function _mintSupplyChecked(address account, uint256 id, uint256 amount) private {
    uint256 currentSupply = tokens[id].currentSupply;
    uint256 maxSupply = tokens[id].maxSupply;
    require(currentSupply + amount <= maxSupply, "not enough supply");

    tokens[id].currentSupply = currentSupply + amount;
    _mint(account, id, amount, "");
  }

  function _random() private returns (uint256) {
    // TODO: NOT SAFE.
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _seed)));
    _seed = randomNumber;
    return randomNumber;
  }
}
