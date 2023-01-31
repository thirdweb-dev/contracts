// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../lib/TWStringSet.sol";
import "../interface/plugin/IPluginRegistry.sol";
import "../PermissionsEnumerable.sol";

contract PluginRegistry is IPluginRegistry, PermissionsEnumerable {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _defaultAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    TWStringSet.Set private pluginNames;
    mapping(string => Plugin) private plugins;
    mapping(bytes4 => PluginMetadata) private pluginMetadata;

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function addPlugin(Plugin memory _plugin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory name = _plugin.metadata.name;

        require(
            bytes(name).length > 0 && _plugin.metadata.implementation != address(0),
            "PluginRegistry: invalid metadata."
        );

        require(pluginNames.add(name), "PluginRegistry: plugin already exists.");
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
        require(selSigMatch, "PluginRegistry: fn selector and signature mismatch.");
    }

    function updatePlugin(Plugin memory _plugin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory name = _plugin.metadata.name;
        require(
            bytes(name).length > 0 && _plugin.metadata.implementation != address(0),
            "PluginRegistry: invalid metadata."
        );
        require(pluginNames.contains(name), "PluginRegistry: plugin does not exist.");

        address oldImplementation = plugins[name].metadata.implementation;
        require(_plugin.metadata.implementation != oldImplementation, "PluginRegistry: re-adding same plugin.");

        plugins[name].metadata = _plugin.metadata;
        delete plugins[name].functions;

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

            emit PluginUpdated(
                oldImplementation,
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
        require(selSigMatch, "PluginRegistry: fn selector and signature mismatch.");
    }

    function removePlugin(string memory _pluginName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(pluginNames.remove(_pluginName), "PluginRegistry: plugin does not exists.");

        address implementation = plugins[_pluginName].metadata.implementation;
        PluginFunction[] memory pluginFunctions = plugins[_pluginName].functions;
        delete plugins[_pluginName];

        uint256 len = pluginFunctions.length;
        for (uint256 i = 0; i < len; i += 1) {
            emit PluginRemoved(
                implementation,
                pluginFunctions[i].functionSelector,
                pluginFunctions[i].functionSignature
            );
            delete pluginMetadata[pluginFunctions[i].functionSelector];
        }
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
        require(pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return plugins[_pluginName].functions;
    }

    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginMetadata memory metadata = pluginMetadata[_functionSelector];
        require(metadata.implementation != address(0), "PluginRegistry: no plugin for function.");
        return metadata;
    }

    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        require(pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return plugins[_pluginName].metadata.implementation;
    }

    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        require(pluginNames.contains(_pluginName), "PluginRegistry: plugin does not exist.");
        return plugins[_pluginName];
    }
}
