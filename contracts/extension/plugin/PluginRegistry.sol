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

    // mapping(string => PluginFunction[]) private pluginFunctions;
    mapping(bytes4 => PluginMetadata) private pluginData;

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function addPlugin(Plugin memory _plugin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory name = _plugin.metadata.name;

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

            pluginData[_plugin.functions[i].functionSelector] = _plugin.metadata;
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
        require(pluginNames.contains(name), "PluginRegistry: plugin does not exist.");

        address oldImplementation = plugins[name].metadata.implementation;
        require(_plugin.metadata.implementation != oldImplementation, "PluginRegistry: re-adding same plugin.");

        plugins[name].metadata = _plugin.metadata;
        delete plugins[name].functions;

        bool selSigMatch = false;
        uint256 len = _plugin.functions.length;

        for (uint256 i = 0; i < len; i += 1) {
            selSigMatch =
                _plugin.functions[i].functionSelector ==
                bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature)));
            if (!selSigMatch) {
                break;
            }

            pluginData[_plugin.functions[i].functionSelector] = _plugin.metadata;
            plugins[name].functions.push(_plugin.functions[i]);

            emit PluginUpdated(
                oldImplementation,
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
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
            delete pluginData[pluginFunctions[i].functionSelector];
        }
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function isApprovedPlugin(bytes4 _functionSelector, address _plugin) external view returns (bool) {
        address pluginAddress = pluginData[_functionSelector].implementation;
        return pluginAddress != address(0) && pluginAddress == _plugin;
    }

    function getAllPluginMetadata() external view returns (PluginMetadata[] memory allMetadata) {
        string[] memory names = pluginNames.values();
        uint256 len = names.length;

        allMetadata = new PluginMetadata[](len);
        for (uint256 i = 0; i < len; i += 1) {
            allMetadata[i] = plugins[names[i]].metadata;
        }
    }

    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        string[] memory names = pluginNames.values();
        uint256 len = names.length;

        allPlugins = new Plugin[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allPlugins[i] = plugins[names[i]];
        }
    }

    function getAllFunctionsOfPlugin(string memory _pluginName)
        external
        view
        returns (PluginFunction[] memory functions, address pluginAddress)
    {
        Plugin memory plugin = plugins[_pluginName];

        functions = plugin.functions;
        pluginAddress = plugin.metadata.implementation;
    }

    function getPluginForFunction(bytes4 _functionSelector) external view returns (address) {
        return pluginData[_functionSelector].implementation;
    }

    function getPluginMetadataForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        return pluginData[_functionSelector];
    }
}
