// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/ITWRouter.sol";

// Extensions & libraries
import "../lib/TWStringSet.sol";
import "../extension/Multicall.sol";

// Plugin pattern imports
import "./Router.sol";
import "./DefaultPluginSet.sol";
import "./PluginState.sol";
import "./interface/IPluginRegistry.sol";

abstract contract TWRouter is ITWRouter, Multicall, PluginState, Router {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The DefaultPluginSet that stores default plugins of the router.
    address public immutable defaultPluginSet;

    /// @notice The PluginRegistry that stores all latest, vetted plugins available to router.
    address public immutable pluginRegistry;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _pluginRegistry, string[] memory _pluginNames) {
        pluginRegistry = _pluginRegistry;

        DefaultPluginSet map = new DefaultPluginSet();
        defaultPluginSet = address(map);

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
        require(_canSetPlugin(), "TWRouter: caller not authorized");

        Plugin memory plugin = IPluginRegistry(pluginRegistry).getPlugin(_pluginName);

        _addPlugin(plugin);
    }

    /// @dev Updates an existing plugin in the router, or overrides a default plugin.
    function updatePlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "TWRouter: caller not authorized");

        Plugin memory plugin = IPluginRegistry(pluginRegistry).getPlugin(_pluginName);

        _updatePlugin(plugin);
    }

    /// @dev Removes an existing plugin from the router.
    function removePlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "TWRouter: caller not authorized");

        _removePlugin(_pluginName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all plugins stored. Override default lugins stored in router are
     *          given precedence over default plugins in DefaultPluginSet.
     */
    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        Plugin[] memory mapPlugins = IDefaultPluginSet(defaultPluginSet).getAllPlugins();
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

    /// @dev Returns the plugin metadata and functions for a given plugin.
    function getPlugin(string memory _pluginName) public view returns (Plugin memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        bool isLocalPlugin = data.pluginNames.contains(_pluginName);

        return isLocalPlugin ? data.plugins[_pluginName] : IDefaultPluginSet(defaultPluginSet).getPlugin(_pluginName);
    }

    /// @dev Returns the plugin's implementation smart contract address.
    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        return getPlugin(_pluginName).metadata.implementation;
    }

    /// @dev Returns all functions that belong to the given plugin contract.
    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        return getPlugin(_pluginName).functions;
    }

    /// @dev Returns the plugin metadata for a given function.
    function getPluginForFunction(bytes4 _functionSelector) public view returns (PluginMetadata memory) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];

        bool isLocalPlugin = metadata.implementation != address(0);

        return isLocalPlugin ? metadata : IDefaultPluginSet(defaultPluginSet).getPluginForFunction(_functionSelector);
    }

    /// @dev Returns the plugin implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector)
        public
        view
        override
        returns (address pluginAddress)
    {
        return getPluginForFunction(_functionSelector).implementation;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetPlugin() internal view virtual returns (bool);
}
