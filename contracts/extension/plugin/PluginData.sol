// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IPlugin.sol";
import "../../lib/TWStringSet.sol";

library PluginDataStorage {
    bytes32 public constant PLUGIN_DATA_STORAGE_POSITION = keccak256("plugin.datastore.storage");

    struct Data {
        TWStringSet.Set pluginNames;
        mapping(string => IPlugin.Plugin) plugins;
        mapping(bytes4 => IPlugin.PluginMetadata) pluginMetadata;
    }

    function pluginDataStorage() internal pure returns (Data storage pluginData) {
        bytes32 position = PLUGIN_DATA_STORAGE_POSITION;
        assembly {
            pluginData.slot := position
        }
    }
}

contract PluginData is IPlugin {
    using TWStringSet for TWStringSet.Set;

    /// @dev Add functionality to the contract.
    function _addPlugin(Plugin memory _plugin) internal {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();

        string memory name = _plugin.metadata.name;

        require(data.pluginNames.add(name), "PluginData: plugin already exists.");
        data.plugins[name].metadata = _plugin.metadata;

        uint256 len = _plugin.functions.length;
        bool selSigMatch = false;

        for (uint256 i = 0; i < len; i += 1) {
            selSigMatch =
                _plugin.functions[i].functionSelector ==
                bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature)));
            if (!selSigMatch) {
                break;
            }

            data.pluginMetadata[_plugin.functions[i].functionSelector] = _plugin.metadata;
            data.plugins[name].functions.push(_plugin.functions[i]);

            emit PluginAdded(
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
        require(selSigMatch, "PluginData: fn selector and signature mismatch.");
    }

    /// @dev Update or override existing functionality.
    function _updatePlugin(Plugin memory _plugin) internal {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();

        string memory name = _plugin.metadata.name;
        require(data.pluginNames.contains(name), "PluginData: plugin does not exist.");

        address oldImplementation = data.plugins[name].metadata.implementation;
        require(_plugin.metadata.implementation != oldImplementation, "PluginData: re-adding same plugin.");

        data.plugins[name].metadata = _plugin.metadata;
        delete data.plugins[name].functions;

        uint256 len = _plugin.functions.length;
        bool selSigMatch = false;

        for (uint256 i = 0; i < len; i += 1) {
            selSigMatch =
                _plugin.functions[i].functionSelector ==
                bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature)));
            if (!selSigMatch) {
                break;
            }

            data.pluginMetadata[_plugin.functions[i].functionSelector] = _plugin.metadata;
            data.plugins[name].functions.push(_plugin.functions[i]);

            emit PluginUpdated(
                oldImplementation,
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
        require(selSigMatch, "PluginData: fn selector and signature mismatch.");
    }

    /// @dev Remove existing functionality from the contract.
    function _removePlugin(string memory _pluginName) internal {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();

        require(data.pluginNames.remove(_pluginName), "PluginData: plugin does not exists.");

        address implementation = data.plugins[_pluginName].metadata.implementation;
        PluginFunction[] memory pluginFunctions = data.plugins[_pluginName].functions;
        delete data.plugins[_pluginName];

        uint256 len = pluginFunctions.length;
        for (uint256 i = 0; i < len; i += 1) {
            emit PluginRemoved(
                implementation,
                pluginFunctions[i].functionSelector,
                pluginFunctions[i].functionSignature
            );
            delete data.pluginMetadata[pluginFunctions[i].functionSelector];
        }
    }
}
