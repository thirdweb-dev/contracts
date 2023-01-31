// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IPluginMap.sol";
import "../../lib/TWStringSet.sol";
import "./PluginData.sol";

contract PluginMap is IPluginMap, PluginData {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    address private deployer;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        deployer = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function setPlugin(Plugin memory _plugin) external {
        require(msg.sender == deployer, "PluginMap: unauthorized caller.");
        _addPlugin(_plugin);
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
        require(data.pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return data.plugins[_pluginName].functions;
    }

    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];
        require(metadata.implementation != address(0), "PluginMap: no plugin for function.");
        return metadata;
    }

    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        require(data.pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return data.plugins[_pluginName].metadata.implementation;
    }

    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        require(data.pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return data.plugins[_pluginName];
    }
}
