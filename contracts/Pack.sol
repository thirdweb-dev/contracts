// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

import "./ControlCenter.sol";
import "./interfaces/RNGInterface.sol";

contract Pack is ERC1155PresetMinterPauser {

  ControlCenter internal controlCenter;
  string public constant HANDLER = "HANDLER";

  uint public currentTokenId;

  struct Token {
    address creator;
    string uri;
    uint circulatingSupply;
  }

  /// @dev tokenId => Token state.
  mapping(uint => Token) public tokens;

  modifier onlyHandler() {
    require(msg.sender == controlCenter.getModule(HANDLER), "Only the protocol pack token handler can call this function.");
    _;
  }

  constructor(address _controlCenter) ERC1155PresetMinterPauser("") {
    controlCenter = ControlCenter(_controlCenter);
    _setupRole(DEFAULT_ADMIN_ROLE, _controlCenter);
    _setupRole(PAUSER_ROLE, _controlCenter);

    revokeRole(MINTER_ROLE, msg.sender);
    revokeRole(PAUSER_ROLE, msg.sender);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @dev Called by `HANDLER` to mint new tokens.
  function mintToken(
    address _creator,
    uint _id,
    uint _amount,
    string calldata _uri
  ) external onlyHandler {

    // Update token state in mapping.
    if(tokens[_id].creator != address(0)) {
      tokens[_id].circulatingSupply += _amount;
    } else {
      tokens[_id] = Token({
        creator: _creator,
        uri: _uri,
        circulatingSupply: _amount
      });
    }

    // Mint tokens to pack creator.
    mint(_creator, _id, _amount, "");
  }

  /// @dev Overriding `burn`
  function burn(address account, uint256 id, uint256 value) public override onlyHandler {
    super.burn(account, id, value);
    
    tokens[id].circulatingSupply -= value;
  }

  /// @dev Overriding `burnBatch`
  function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override onlyHandler {
    super.burnBatch(account, ids, values);
    
    for(uint i = 0; i < ids.length; i++) {
      tokens[ids[i]].circulatingSupply -= values[i];
    }
  }


  /// @dev Returns and then increments `currentTokenId`
  function _tokenId() public onlyHandler returns (uint tokenId) {
    tokenId = currentTokenId;
    currentTokenId += 1;
  }

  /// @notice See the ERC1155 API. Returns the token URI of the token with id `tokenId`
  function uri(uint id) public view override returns (string memory) {
    return tokens[id].uri;
  }
}