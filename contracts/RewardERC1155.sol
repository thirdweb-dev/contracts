// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

import "./PackControl.sol";
import "./interfaces/RNGInterface.sol";

contract RewardERC1155 is ERC1155PresetMinterPauser {

  PackControl internal controlCenter;
  string public constant HANDLER_MODULE_NAME = "HANDLER";

  enum RewardType { ERC20, ERC721, ERC1155 }

  uint public currentTokenId;

  struct Token {
    address creator;
    string uri;
    uint circulatingSupply;
    uint tokenType;
  }

  event TokenTransfer(address indexed from, address indexed to, uint[] tokenIds, uint[] amounts, uint tokenType);
  event TokenBurnSingle(address indexed burner, uint tokenId, uint amount);
  event TokenBurnBatch(address indexed burner, uint[] tokenIds, uint[] amounts);

  /// @dev tokenId => Token state.
  mapping(uint => Token) public tokens;

  modifier onlyControlCenter() {
    require(msg.sender == address(controlCenter), "Only the protocol control center can call this function.");
    _;
  }

  modifier onlyPackHandler() {
    require(msg.sender == controlCenter.getModule(HANDLER_MODULE_NAME), "Only the protocol pack token handler can call this function.");
    _;
  }

  constructor(address _controlCenter) ERC1155PresetMinterPauser("") {
    controlCenter = PackControl(_controlCenter);
    grantRole(DEFAULT_ADMIN_ROLE, _controlCenter);
    grantRole(PAUSER_ROLE, _controlCenter);
  }

  /// @dev Called by the pack handler to mint new tokens.
  function mintToken(
    address _creator,
    uint _id,
    uint _amount,
    string calldata _uri,
    uint _rewardType
  ) external onlyPackHandler {

    // Update token state in mapping.

    if(tokens[_id].creator != address(0)) {
      tokens[_id].circulatingSupply += _amount;
    } else {
      tokens[_id] = Token({
        creator: _creator,
        uri: _uri,
        tokenType: _rewardType,
        circulatingSupply: _amount
      });
    }

    // Mint tokens to pack creator.
    mint(_creator, _id, _amount, "");
  }

  /// @dev Overriding `burn`
  function burn(address account, uint256 id, uint256 value) public override onlyPackHandler {
    super.burn(account, id, value);
    
    tokens[id].circulatingSupply -= value;
    emit TokenBurnSingle(account, id, value);
  }

  /// @dev Overriding `burnBatch`
  function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override onlyPackHandler {
    super.burnBatch(account, ids, values);
    
    for(uint i = 0; i < ids.length; i++) {
      tokens[ids[i]].circulatingSupply -= values[i];
    }

    emit TokenBurnBatch(account, ids, values);
  }


  /// @dev Returns and then increments `currentTokenId`
  function _tokenId() public onlyPackHandler returns (uint tokenId) {
    tokenId = currentTokenId;
    currentTokenId += 1;
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
   * @dev See OpenZeppelin ERC1155PresetMinterPauser signature of `_beforeTokenTransfer`
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {

    if(ids.length == 1) { 
      emit TokenTransfer(from, to, ids, amounts, tokens[ids[0]].tokenType);
    } else {

      uint typeOfToken;

      for (uint i = 0; i < ids.length; i++) {
        uint tokenId = ids[i];

        if(i == 0) {
          typeOfToken = tokens[tokenId].tokenType;
          continue;
        } else if(tokens[tokenId].tokenType != typeOfToken) {
          revert("Can only transfer a batch of the same type of token.");
        }
      }

      emit TokenTransfer(from, to, ids, amounts, typeOfToken);
    }
  }
}