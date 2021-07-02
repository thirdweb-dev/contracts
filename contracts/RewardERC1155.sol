// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

import "./PackControl.sol";
import "./interfaces/RNGInterface.sol";
import "./libraries/Reward.sol";

contract RewardERC1155 is ERC1155PresetMinterPauser {

  PackControl internal controlCenter;
  string public constant PACK_HANDLER_MODULE_NAME = "PACK_HANDLER";

  uint public currentTokenId;

  struct Token {
    address creator;
    string uri;
    uint circulatingSupply;
    Reward.RewardType rewardType;
  }

  /// @dev tokenId => Token state.
  mapping(uint => Token) public tokens;
  
  /// @dev tokenId => Reward state.
  mapping(uint => Reward.ERC20Reward) public erc20Rewards;
  mapping(uint => Reward.ERC721Reward) public erc721Rewards;
  mapping(uint => Reward.ERC1155Reward) public erc1155Rewards;

  modifier onlyHandler() {
    require(msg.sender == controlCenter.getModule(PACK_HANDLER_MODULE_NAME), "Only the protocol pack token handler can call this function.");
    _;
  }

  constructor(address _controlCenter) ERC1155PresetMinterPauser("") {
    controlCenter = PackControl(_controlCenter);
    grantRole(DEFAULT_ADMIN_ROLE, _controlCenter);
    grantRole(PAUSER_ROLE, _controlCenter);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @dev Called by the pack handler to mint new tokens.
  function mintToken(
    address _underlyingAsset,
    uint _underlyingAssetAmount,
    uint _underlyingAssetId,

    address _creator,
    uint _id,
    uint _amount,
    string calldata _uri,
    Reward.RewardType _rewardType
  ) external onlyHandler {

    // Update token state in mapping.

    if(tokens[_id].creator != address(0)) {
      tokens[_id].circulatingSupply += _amount;
    } else {

      tokens[_id] = Token({
        creator: _creator,
        uri: _uri,
        rewardType: _rewardType,
        circulatingSupply: _amount
      });

      if(_rewardType == Reward.RewardType.ERC20) {
        erc20Rewards[_id] = Reward.ERC20Reward({
          asset: _underlyingAsset,
          totalTokenAmount: _underlyingAssetAmount,
          rewardTokenAmount: _amount
        });
      } else if (_rewardType == Reward.RewardType.ERC721) {
        erc721Rewards[_id] = Reward.ERC721Reward({
          contractAddress: _underlyingAsset,
          tokenId: _underlyingAssetId
        });
      } else if (_rewardType == Reward.RewardType.ERC1155) {
        erc1155Rewards[_id] = Reward.ERC1155Reward({
          contractAddress: _underlyingAsset,
          tokenId: _underlyingAssetId,
          totalTokenAmount: _underlyingAssetAmount,
          rewardTokenAmount: _amount
        });
      }
      
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