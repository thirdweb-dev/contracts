// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IRouter.sol";

import "../../lib/TWStringSet.sol";
import "../../eip/ERC165.sol";
import "../Multicall.sol";

import { PluginMap } from "./PluginMap.sol";
import { IPluginRegistry } from "../interface/plugin/IPluginRegistry.sol";

import "./PluginState.sol";

abstract contract Router is PluginState, Multicall, ERC165, IRouter {
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
                                ERC 165
    //////////////////////////////////////////////////////////////*/

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRouter).interfaceId || super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    fallback() external payable virtual {
        address _pluginAddress = _getPluginForFunction(msg.sig);
        if (_pluginAddress == address(0)) {
            _pluginAddress = IPluginMap(pluginMap).getPluginForFunction(msg.sig).implementation;
        }
        _delegate(_pluginAddress);
    }

    receive() external payable {}

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
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

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the plugin implementation address stored in router, for the given function.
    function _getPluginForFunction(bytes4 _functionSelector) internal view returns (address) {
        PluginStateStorage.Data storage data = PluginStateStorage.pluginStateStorage();
        return data.pluginMetadata[_functionSelector].implementation;
    }

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetPlugin() internal view virtual returns (bool);
}
