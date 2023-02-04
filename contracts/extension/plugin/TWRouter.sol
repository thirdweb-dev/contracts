// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "../interface/plugin/ITWRouter.sol";

// Extensions & libraries
import "../../lib/TWStringSet.sol";
import "../Multicall.sol";

// Plugin pattern imports
import "./Router.sol";
import "./PluginMap.sol";
import "./PluginState.sol";
import "../interface/plugin/IPluginRegistry.sol";

abstract contract TWRouter is ITWRouter, Multicall, PluginState, Router {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The PluginMap that stores default plugins of the router.
    address public immutable pluginMap;

    /// @notice The PluginRegistry that stores all latest, vetted plugins available to router.
    address public immutable pluginRegistry;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _pluginRegistry, string[] memory _pluginNames) {
        pluginRegistry = _pluginRegistry;

        PluginMap map = new PluginMap();
        pluginMap = address(map);

        uint256 len = _pluginNames.length;

        for (uint256 i = 0; i < len; i += 1) {
            Plugin memory plugin = IPluginRegistry(_pluginRegistry).getPlugin(_pluginNames[i]);
            map.setPlugin(plugin);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new plugin to the router.
    function addPlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "Router: caller not authorized");

        Plugin memory plugin = IPluginRegistry(pluginRegistry).getPlugin(_pluginName);

        _addPlugin(plugin);
    }

    /// @dev Updates an existing plugin in the router, or overrides a default plugin.
    function updatePlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "Router: caller not authorized");

        Plugin memory plugin = IPluginRegistry(pluginRegistry).getPlugin(_pluginName);

        _updatePlugin(plugin);
    }

    /// @dev Removes an existing plugin from the router.
    function removePlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "Router: caller not authorized");

        _removePlugin(_pluginName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all plugins stored. Override default lugins stored in router are
     *          given precedence over default plugins in PluginMap.
     */
    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        Plugin[] memory mapPlugins = IPluginMap(pluginMap).getAllPlugins();
        uint256 mapPluginsLen = mapPlugins.length;

        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        string[] memory names = data.pluginNames.values();
        uint256 namesLen = names.length;

        uint256 overrides = 0;
        for (uint256 i = 0; i < mapPluginsLen; i += 1) {
            if (data.pluginNames.contains(mapPlugins[i].metadata.name)) {
                overrides += 1;
            }
        }

        uint256 total = (namesLen + mapPluginsLen) - overrides;

        allPlugins = new Plugin[](total);
        uint256 idx = 0;

        for (uint256 i = 0; i < mapPluginsLen; i += 1) {
            string memory name = mapPlugins[i].metadata.name;
            if (!data.pluginNames.contains(name)) {
                allPlugins[idx] = mapPlugins[i];
                idx += 1;
            }
        }

        for (uint256 i = 0; i < namesLen; i += 1) {
            allPlugins[idx] = data.plugins[names[i]];
            idx += 1;
        }
    }

    /// @dev Returns all functions that belong to the given plugin contract.
    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        bool isOverride = data.pluginNames.contains(_pluginName);
        return
            isOverride
                ? data.plugins[_pluginName].functions
                : IPluginMap(pluginMap).getAllFunctionsOfPlugin(_pluginName);
    }

    /// @dev Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];

        bool isOverride = metadata.implementation != address(0);

        return isOverride ? metadata : IPluginMap(pluginMap).getPluginForFunction(_functionSelector);
    }

    /// @dev Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        bool isOverride = data.pluginNames.contains(_pluginName);

        return
            isOverride
                ? data.plugins[_pluginName].metadata.implementation
                : IPluginMap(pluginMap).getPluginImplementation(_pluginName);
    }

    /// @dev Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        bool isOverride = data.pluginNames.contains(_pluginName);

        return isOverride ? data.plugins[_pluginName] : IPluginMap(pluginMap).getPlugin(_pluginName);
    }

    /// @dev Returns the plugin implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector)
        public
        view
        override
        returns (address pluginAddress)
    {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        pluginAddress = data.pluginMetadata[_functionSelector].implementation;
        if (pluginAddress == address(0)) {
            pluginAddress = IPluginMap(pluginMap).getPluginForFunction(msg.sig).implementation;
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetPlugin() internal view virtual returns (bool);
}
