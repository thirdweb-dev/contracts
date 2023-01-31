// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IPluginMap.sol";
import "../../lib/TWStringSet.sol";

contract PluginMap is IPluginMap {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    address private deployer;

    TWStringSet.Set private pluginNames;
    mapping(string => Plugin) private plugins;
    mapping(bytes4 => PluginMetadata) private pluginMetadata;

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
        _setPlugin(_plugin);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        string[] memory names = pluginNames.values();
        uint256 len = names.length;

        allPlugins = new Plugin[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allPlugins[i] = plugins[names[i]];
        }
    }

    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        require(pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return plugins[_pluginName].functions;
    }

    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginMetadata memory metadata = pluginMetadata[_functionSelector];
        require(metadata.implementation != address(0), "PluginMap: no plugin for function.");
        return metadata;
    }

    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        require(pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return plugins[_pluginName].metadata.implementation;
    }

    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        require(pluginNames.contains(_pluginName), "PluginMap: plugin does not exist.");
        return plugins[_pluginName];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Add functionality to the contract.
    function _setPlugin(Plugin memory _plugin) internal {
        string memory name = _plugin.metadata.name;

        require(pluginNames.add(name), "PluginMap: plugin already exists.");
        plugins[name].metadata = _plugin.metadata;

        uint256 len = _plugin.functions.length;
        bool selSigMatch = false;

        for (uint256 i = 0; i < len; i += 1) {
            selSigMatch =
                _plugin.functions[i].functionSelector ==
                bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature)));
            if (!selSigMatch) {
                break;
            }

            pluginMetadata[_plugin.functions[i].functionSelector] = _plugin.metadata;
            plugins[name].functions.push(_plugin.functions[i]);

            emit PluginAdded(
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
        require(selSigMatch, "PluginMap: fn selector and signature mismatch.");
    }
}
