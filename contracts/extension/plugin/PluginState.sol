// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IPlugin.sol";
import "../../lib/TWStringSet.sol";

library PluginStateStorage {
    bytes32 public constant PLUGIN_STATE_STORAGE_POSITION = keccak256("plugin.state.storage");

    struct Data {
        TWStringSet.Set pluginNames;
        mapping(string => IPlugin.Plugin) plugins;
        mapping(bytes4 => IPlugin.PluginMetadata) pluginMetadata;
    }

    function pluginStateStorage() internal pure returns (Data storage pluginStateData) {
        bytes32 position = PLUGIN_STATE_STORAGE_POSITION;
        assembly {
            pluginStateData.slot := position
        }
    }
}

contract PluginState is IPlugin {
    using TWStringSet for TWStringSet.Set;

    /// @dev Stores a new plugin in the contract.
    function _addPlugin(Plugin memory _plugin) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

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

    /// @dev Updates / overrides an existing plugin in the contract.
    function _updatePlugin(Plugin memory _plugin) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

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

    /// @dev Removes an existing plugin from the contract.
    function _removePlugin(string memory _pluginName) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

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
