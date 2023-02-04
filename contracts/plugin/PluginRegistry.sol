// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IPluginRegistry.sol";

// Extensions
import "./PluginState.sol";
import "../lib/TWStringSet.sol";
import "../extension/PermissionsEnumerable.sol";

contract PluginRegistry is IPluginRegistry, PluginState, PermissionsEnumerable {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _defaultAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a new plugin to the registry.
    function addPlugin(Plugin memory _plugin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addPlugin(_plugin);
    }

    /// @notice Updates an existing plugin in the registry.
    function updatePlugin(Plugin memory _plugin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatePlugin(_plugin);
    }

    /// @notice Remove an existing plugin from the registry.
    function removePlugin(string memory _pluginName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removePlugin(_pluginName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all plugins stored.
    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        string[] memory names = data.pluginNames.values();
        uint256 len = names.length;

        allPlugins = new Plugin[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allPlugins[i] = data.plugins[names[i]];
        }
    }

    /// @notice Returns all functions that belong to the given plugin contract.
    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        require(data.pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return data.plugins[_pluginName].functions;
    }

    /// @notice Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];
        require(metadata.implementation != address(0), "PluginRegistry: no plugin for function.");
        return metadata;
    }

    /// @notice Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        require(data.pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return data.plugins[_pluginName].metadata.implementation;
    }

    /// @notice Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        require(data.pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return data.plugins[_pluginName];
    }
}
