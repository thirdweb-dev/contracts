// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPluginMap.sol";

interface IPluginRegistry is IPluginMap {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new plugin to the registry.
    function addPlugin(Plugin memory plugin) external;

    /// @dev Updates an existing plugin in the registry.
    function updatePlugin(Plugin memory plugin) external;

    /// @dev Remove an existing plugin from the registry.
    function removePlugin(string memory plugin) external;
}
