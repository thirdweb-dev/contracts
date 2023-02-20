// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "./IDefaultPluginSet.sol";

interface IBaseRouter is IDefaultPluginSet {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new plugin to the router.
    function addPlugin(Plugin memory plugin) external;

    /// @dev Updates an existing plugin in the router, or overrides a default plugin.
    function updatePlugin(Plugin memory plugin) external;

    /// @dev Removes an existing plugin from the router.
    function removePlugin(string memory pluginName) external;
}
