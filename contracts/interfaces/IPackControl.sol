// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// @notice Provides the interface for Pack Protocol's central control center.
interface IPackControl {

  /// @notice Sets the ERC1155 part of the pack protocol.
  function setPackERC1155(address _packERC1155) external;

  /// @notice Sets the RNG for pack protocol.
  function setPackRNG(address _rng) external;

  /// @notice Sets the address for the Market part of the pack protocol.
  function setPackMarket(address _market) external;
}