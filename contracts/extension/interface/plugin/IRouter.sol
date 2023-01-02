// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IMap.sol";

interface IRouter is IMap {
    /// @dev Emitted when a functionality is added, or plugged-in.
    event PluginAdded(bytes4 indexed selector, address indexed pluginAddress);

    /// @dev Emitted when a functionality is updated or overridden.
    event PluginUpdated(bytes4 indexed selector, address indexed oldPluginAddress, address indexed newPluginAddress);

    /// @dev Emitted when a functionality is removed.
    event PluginRemoved(bytes4 indexed selector, address indexed pluginAddress);

    /// @dev Add functionality to the contract.
    function addPlugin(Plugin memory _plugin) external;

    /// @dev Update or override existing functionality.
    function updatePlugin(Plugin memory _plugin) external;

    /// @dev Remove existing functionality from the contract.
    function removePlugin(bytes4 _selector) external;
}
