pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
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

  struct Pack {
    address owner;
    uint256 numRewardOnOpen;
    uint256 rarityDenominator;
    uint256[] rewardTokenIds;
  }

  uint256 private _currentTokenId = 0;
  uint256 private _seed;

  mapping(uint256 => Token) public tokens;
  mapping(uint256 => Pack) public packs;
  mapping(uint256 => Reward) public rewards;

  constructor() ERC1155("") {
  }

  function createPack(string memory tokenURI) external returns (uint256 tokenId) {
    tokenId = _currentTokenId;
    _currentTokenId += 1;

    tokens[tokenId] = Token({
      uri: tokenURI,
      currentSupply: 0,
      maxSupply: 100,
      tokenType: TokenType.Pack
    });

    Pack storage pack = packs[tokenId];
    pack.owner = msg.sender;
    pack.numRewardOnOpen = 1;
    pack.rarityDenominator = REWARD_RARITY_DENOMINATOR;
  }

  function openPack(uint256 packId) external {
    require(balanceOf(msg.sender, packId) > 0, "insufficient pack");

    Pack memory pack = packs[packId];
    require(pack.rewardTokenIds.length > 0, "no rewards available");

    uint256 prob = _random().mod(pack.rarityDenominator);
    uint256 index = prob.mod(pack.rewardTokenIds.length);

    _burn(msg.sender, packId, 1);
    _mintSupplyChecked(msg.sender, pack.rewardTokenIds[index], 1);
  }

  function buyPack(uint256 packId, uint256 amount) external {
    require(tokens[packId].currentSupply + amount <= tokens[packId].maxSupply, "not enough supply");
    _mintSupplyChecked(msg.sender, packId, amount);
  }

  function addRewards(uint256 packId, string[] memory tokenUris) external {
    require(packs[packId].owner == msg.sender, "not the pack owner");

    for (uint256 i = 0; i < tokenUris.length; i++) {
      string memory tokenUri = tokenUris[i];

      uint256 tokenId = _currentTokenId;
      _currentTokenId += 1;

      tokens[tokenId] = Token({
        uri: tokenUri,
        currentSupply: 0,
        maxSupply: 100,
        tokenType: TokenType.Reward
      });
      packs[packId].rewardTokenIds.push(tokenId);
      rewards[tokenId].rarityNumerator = 0;
    }
  }

  function uri(uint256 id) public view override returns (string memory) {
    return tokens[id].uri;
  }

  function _mintSupplyChecked(address account, uint256 id, uint256 amount) private {
    uint256 currentSupply = tokens[id].currentSupply;
    uint256 maxSupply = tokens[id].maxSupply;
    require(currentSupply <= maxSupply);
    require(currentSupply <= currentSupply + amount);

    tokens[id].currentSupply = currentSupply + amount;
    _mint(account, id, amount, "");
  }

  function _random() private returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _seed)));
    _seed = randomNumber;
    return randomNumber;
  }
}
