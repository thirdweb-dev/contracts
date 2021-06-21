// ██████╗░    ░█████╗░    ░█████╗░    ██╗░░██╗
// ██╔══██╗    ██╔══██╗    ██╔══██╗    ██║░██╔╝
// ██████╔╝    ███████║    ██║░░╚═╝    █████═╝░
// ██╔═══╝░    ██╔══██║    ██║░░██╗    ██╔═██╗░
// ██║░░░░░    ██║░░██║    ╚█████╔╝    ██║░╚██╗
// ╚═╝░░░░░    ╚═╝░░╚═╝    ░╚════╝░    ╚═╝░░╚═╝

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./interfaces/IPackControl.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract PackControl is AccessControl, IPackControl {

  bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");

  address public packERC1155;
  address public packMarket;
  address public packRNG;

  modifier onlyProtocolAdmin() {
    require(hasRole(PROTOCOL_ADMIN, msg.sender), "Only protocol admins can call this function.");
    _;
  }

  constructor() {
    grantRole(PROTOCOL_ADMIN, msg.sender);
  }

  /// @notice Sets the ERC1155 part of the pack protocol.
  function setPackERC1155(address _packERC1155) external override onlyProtocolAdmin {
    packERC1155 = _packERC1155;
  }

  /// @notice Sets the address for the Market part of the pack protocol.
  function setPackMarket(address _market) external override onlyProtocolAdmin {
    packMarket = _market;
  }

  /// @notice Sets the RNG for pack protocol.
  function setPackRNG(address _rng) external override onlyProtocolAdmin {
    packRNG = _rng;
  }

  /// @notice Pauses all activity in the ERC1155 part of the protocol.
  function pausePackToken() external onlyProtocolAdmin {
    ERC1155PresetMinterPauser(packERC1155).pause();
  }

  /// @notice Grants the `PROTOCOL_ADMIN` role to `_newAdmin`.
  function makeProtocolAdmin(address _newAdmin) external onlyProtocolAdmin {
    grantRole(PROTOCOL_ADMIN, _newAdmin);
  } 
}