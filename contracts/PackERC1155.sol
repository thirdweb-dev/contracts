// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "./interfaces/RNGInterface.sol";

contract PackERC1155 is ERC1155PresetMinterPauser {

  address public controlCenter;
  RNGInterface internal rng;

  uint public currentTokenId;

  enum TokenType { Pack, Reward }

  struct Token {
    address creator;
    string uri;
    uint rarityUnit;
    uint maxSupply;

    TokenType tokenType;
  }

  event RNG(address _newRNG);
  event TokenTransferSingle(address indexed from, address indexed to, uint tokenId, uint amount, TokenType tokenType);
  event TokenTransferBatch(address indexed from, address indexed to, uint[] tokenIds, uint[] amounts, TokenType tokenType);

  /// @notice Maps a `tokenId` to its Token state
  mapping(uint => Token) public tokens;

  constructor(address _controlCenter) ERC1155PresetMinterPauser("") {
    controlCenter = _controlCenter;
  }

  modifier onlyControlCenter {
    require(msg.sender == controlCenter, "Only the Pack protocol control center can access this function.");
    _;
  }

  /// @notice Lets control center set the RNG used by the Pack ERC1155 contract.
  function setRNG(address _rng) external onlyControlCenter {
    rng = RNGInterface(_rng);
    emit RNG(_rng);
  }

  /// @dev Returns and then increments `currentTokenId`
  function _tokenId() internal returns (uint tokenId) {
    tokenId = currentTokenId;
    currentTokenId++;
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