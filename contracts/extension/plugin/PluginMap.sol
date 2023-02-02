// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IPluginMap.sol";
import "../../lib/TWStringSet.sol";
import "./PluginState.sol";

contract PluginMap is IPluginMap, PluginState {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The deployer of PluginMap.
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

    /// @notice Stores a plugin in the PluginMap.
    function setPlugin(Plugin memory _plugin) external {
        require(msg.sender == deployer, "PluginMap: unauthorized caller.");
        _addPlugin(_plugin);
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
        require(data.pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return data.plugins[_pluginName].functions;
    }

    /// @notice Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];
        require(metadata.implementation != address(0), "PluginMap: no plugin for function.");
        return metadata;
    }

    /// @notice Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        require(data.pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return data.plugins[_pluginName].metadata.implementation;
    }

    /// @notice Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        require(data.pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return data.plugins[_pluginName];
    }
}
