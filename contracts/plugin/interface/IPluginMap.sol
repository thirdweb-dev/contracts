// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPlugin.sol";

interface IPluginMap is IPlugin {
    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all plugins stored.
    function getAllPlugins() external view returns (Plugin[] memory);

    /// @dev Returns all functions that belong to the given plugin contract.
    function getAllFunctionsOfPlugin(string memory pluginName) external view returns (PluginFunction[] memory);

    /// @dev Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 functionSelector) external view returns (PluginMetadata memory);

    /// @dev Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory pluginName) external view returns (address);

    /// @dev Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory pluginName) external view returns (Plugin memory);
}
