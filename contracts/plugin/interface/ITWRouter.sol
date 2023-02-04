// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPluginMap.sol";

interface ITWRouter is IPluginMap {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new plugin to the router.
    function addPlugin(string memory pluginName) external;

    /// @dev Updates an existing plugin in the router, or overrides a default plugin.
    function updatePlugin(string memory pluginName) external;

    /// @dev Removes an existing plugin from the router.
    function removePlugin(string memory pluginName) external;
}
