// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../lib/TWStringSet.sol";
import "../interface/plugin/IPluginRegistry.sol";
import "../PermissionsEnumerable.sol";
import "./PluginData.sol";

contract PluginRegistry is IPluginRegistry, PermissionsEnumerable, PluginData {
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

    function addPlugin(Plugin memory _plugin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addPlugin(_plugin);
    }

    function updatePlugin(Plugin memory _plugin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatePlugin(_plugin);
    }

    function removePlugin(string memory _pluginName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removePlugin(_pluginName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();

        string[] memory names = data.pluginNames.values();
        uint256 len = names.length;

        allPlugins = new Plugin[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allPlugins[i] = data.plugins[names[i]];
        }
    }

    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        require(data.pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return data.plugins[_pluginName].functions;
    }

    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];
        require(metadata.implementation != address(0), "PluginRegistry: no plugin for function.");
        return metadata;
    }

    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        require(data.pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return data.plugins[_pluginName].metadata.implementation;
    }

    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        require(data.pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return data.plugins[_pluginName];
    }
}
