// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IPlugin.sol";

// Extensions
import "../lib/TWStringSet.sol";

library PluginStateStorage {
    bytes32 public constant PLUGIN_STATE_STORAGE_POSITION = keccak256("plugin.state.storage");

    struct Data {
        /// @dev Set of names of all plugins stored.
        TWStringSet.Set pluginNames;
        /// @dev Mapping from plugin name => `Plugin` i.e. plugin metadata and functions.
        mapping(string => IPlugin.Plugin) plugins;
        /// @dev Mapping from function selector => plugin metadata of the plugin the function belongs to.
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

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Stores a new plugin in the contract.
    function _addPlugin(Plugin memory _plugin) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        string memory name = _plugin.metadata.name;

        require(data.pluginNames.add(name), "PluginState: plugin already exists.");
        data.plugins[name].metadata = _plugin.metadata;

        require(_plugin.metadata.implementation != address(0), "PluginState: adding plugin without implementation.");

        uint256 len = _plugin.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _plugin.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature))),
                "PluginState: fn selector and signature mismatch."
            );
            require(
                data.pluginMetadata[_plugin.functions[i].functionSelector].implementation == address(0),
                "PluginState: plugin already exists for function."
            );

            data.pluginMetadata[_plugin.functions[i].functionSelector] = _plugin.metadata;
            data.plugins[name].functions.push(_plugin.functions[i]);

            emit PluginAdded(
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
    }

    /// @dev Updates / overrides an existing plugin in the contract.
    function _updatePlugin(Plugin memory _plugin) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        string memory name = _plugin.metadata.name;
        require(data.pluginNames.contains(name), "PluginState: plugin does not exist.");

        address oldImplementation = data.plugins[name].metadata.implementation;
        require(_plugin.metadata.implementation != oldImplementation, "PluginState: re-adding same plugin.");

        data.plugins[name].metadata = _plugin.metadata;

        PluginFunction[] memory oldFunctions = data.plugins[name].functions;
        uint256 oldFunctionsLen = oldFunctions.length;

        delete data.plugins[name].functions;

        for (uint256 i = 0; i < oldFunctionsLen; i += 1) {
            delete data.pluginMetadata[oldFunctions[i].functionSelector];
        }

        uint256 len = _plugin.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _plugin.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_plugin.functions[i].functionSignature))),
                "PluginState: fn selector and signature mismatch."
            );

            data.pluginMetadata[_plugin.functions[i].functionSelector] = _plugin.metadata;
            data.plugins[name].functions.push(_plugin.functions[i]);

            emit PluginUpdated(
                oldImplementation,
                _plugin.metadata.implementation,
                _plugin.functions[i].functionSelector,
                _plugin.functions[i].functionSignature
            );
        }
    }

    /// @dev Removes an existing plugin from the contract.
    function _removePlugin(string memory _pluginName) internal {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();

        require(data.pluginNames.remove(_pluginName), "PluginState: plugin does not exist.");

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
