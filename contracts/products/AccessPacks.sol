// ░█████╗░  ░█████╗░  ░█████╗░  ███████╗  ░██████╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██╔════╝  ██╔════╝  ██╔════╝
// ███████║  ██║░░╚═╝  ██║░░╚═╝  █████╗░░  ╚█████╗░  ╚█████╗░
// ██╔══██║  ██║░░██╗  ██║░░██╗  ██╔══╝░░  ░╚═══██╗  ░╚═══██╗
// ██║░░██║  ╚█████╔╝  ╚█████╔╝  ███████╗  ██████╔╝  ██████╔╝
// ╚═╝░░╚═╝  ░╚════╝░  ░╚════╝░  ╚══════╝  ╚═════╝░  ╚═════╝░


// ██████╗░  ░█████╗░  ░█████╗░  ██╗░░██╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██║░██╔╝  ██╔════╝
// ██████╔╝  ███████║  ██║░░╚═╝  █████═╝░  ╚█████╗░
// ██╔═══╝░  ██╔══██║  ██║░░██╗  ██╔═██╗░  ░╚═══██╗
// ██║░░░░░  ██║░░██║  ╚█████╔╝  ██║░╚██╗  ██████╔╝
// ╚═╝░░░░░  ╚═╝░░╚═╝  ░╚════╝░  ╚═╝░░╚═╝  ╚═════╝░

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract AccessPacks is ERC1155PresetMinterPauser, IERC1155Receiver {

  uint public currentTokenId;

  struct AccessRewards {
    address creator;
    string uri;
    uint supply;
  }

  /// @notice Pack and reward events.
  event RewardsCreated(uint[] rewardIds, string[] rewardURIs, uint[] rewardSupplies);

  /// @dev Reward tokenId => Reward state.
  mapping(uint => AccessRewards) public rewards;

  constructor() ERC1155PresetMinterPauser("") {
    _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
    revokeRole(MINTER_ROLE, msg.sender);
    revokeRole(PAUSER_ROLE, msg.sender);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Lets `msg.sender` create a pack with rewards and list it for sale.
  function createRewards(string[] calldata _rewardURIs, uint[] calldata _rewardSupplies) external returns (uint[] memory rewardIds) {

    require(_rewardURIs.length == _rewardSupplies.length, "Must specify equal number of URIs and supplies.");

    // Get tokenIds and store reward state.
    rewardIds = new uint[](_rewardURIs.length);
    
    for(uint i = 0; i < _rewardURIs.length; i++) {
      rewardIds[i] = currentTokenId;

      rewards[currentTokenId] = AccessRewards({
        creator: msg.sender,
        uri: _rewardURIs[i],
        supply: _rewardSupplies[i]
      });

      currentTokenId++;
    }

    // Mint reward tokens to `msg.sender`
    _setupRole(MINTER_ROLE, msg.sender);
    mintBatch(msg.sender, rewardIds, _rewardSupplies, "");
    revokeRole(MINTER_ROLE, msg.sender);

    emit RewardsCreated(rewardIds, _rewardURIs, _rewardSupplies);
  }

  /// @dev See EIP 1155
  function uri(uint _rewardId) public view override returns (string memory) {
    return rewards[_rewardId].uri;
  }

  /// @dev Returns the creator of reward token
  function creator(uint _rewardId) external view returns (address) {
    return rewards[_rewardId].creator;
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