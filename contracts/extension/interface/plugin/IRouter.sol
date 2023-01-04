// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IPluginMap.sol";

interface IRouter is IPluginMap {
    /// @dev Emitted when a functionality is added, or plugged-in.
    event PluginAdded(bytes4 indexed functionSelector, address indexed pluginAddress);

    /// @dev Emitted when a functionality is updated or overridden.
    event PluginUpdated(
        bytes4 indexed functionSelector,
        address indexed oldPluginAddress,
        address indexed newPluginAddress
    );

    /// @dev Emitted when a functionality is removed.
    event PluginRemoved(bytes4 indexed functionSelector, address indexed pluginAddress);

    /// @dev Add a new plugin to the contract.
    function addPlugin(Plugin memory plugin) external;

    /// @dev Update / override an existing plugin.
    function updatePlugin(Plugin memory plugin) external;

    /// @dev Remove an existing plugin from the contract.
    function removePlugin(bytes4 functionSelector) external;
}
