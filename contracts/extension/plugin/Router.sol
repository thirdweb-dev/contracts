// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IRouter.sol";

import "../../lib/TWStringSet.sol";
import "../../eip/ERC165.sol";
import "../Multicall.sol";

import { PluginMap } from "./PluginMap.sol";
import { IPluginRegistry } from "../interface/plugin/IPluginRegistry.sol";

import "./PluginData.sol";

abstract contract Router is PluginData, Multicall, ERC165, IRouter {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    address public immutable pluginMap;
    address public immutable pluginRegistry;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
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

    /// @dev Add functionality to the contract.
    function addPlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "Router: caller not authorized");

        Plugin memory plugin = IPluginRegistry(pluginRegistry).getPlugin(_pluginName);

        _addPlugin(plugin);
    }

    /// @dev Update or override existing functionality.
    function updatePlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "Router: caller not authorized");

        Plugin memory plugin = IPluginRegistry(pluginRegistry).getPlugin(_pluginName);

        _updatePlugin(plugin);
    }

    /// @dev Remove existing functionality from the contract.
    function removePlugin(string memory _pluginName) external {
        require(_canSetPlugin(), "Router: caller not authorized");

        _removePlugin(_pluginName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function getAllPlugins() external view returns (Plugin[] memory allPlugins) {
        Plugin[] memory mapPlugins = IPluginMap(pluginMap).getAllPlugins();
        uint256 mapPluginsLen = mapPlugins.length;

        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
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

    function getAllFunctionsOfPlugin(string memory _pluginName) external view returns (PluginFunction[] memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        bool isOverride = data.pluginNames.contains(_pluginName);
        return
            isOverride
                ? data.plugins[_pluginName].functions
                : IPluginMap(pluginMap).getAllFunctionsOfPlugin(_pluginName);
    }

    function getPluginForFunction(bytes4 _functionSelector) external view returns (PluginMetadata memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        PluginMetadata memory metadata = data.pluginMetadata[_functionSelector];

        bool isOverride = metadata.implementation != address(0);

        return isOverride ? metadata : IPluginMap(pluginMap).getPluginForFunction(_functionSelector);
    }

    function getPluginImplementation(string memory _pluginName) external view returns (address) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        bool isOverride = data.pluginNames.contains(_pluginName);

        return
            isOverride
                ? data.plugins[_pluginName].metadata.implementation
                : IPluginMap(pluginMap).getPluginImplementation(_pluginName);
    }

    function getPlugin(string memory _pluginName) external view returns (Plugin memory) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        bool isOverride = data.pluginNames.contains(_pluginName);

        return isOverride ? data.plugins[_pluginName] : IPluginMap(pluginMap).getPlugin(_pluginName);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev View address of the plugged-in functionality contract for a given function signature.
    function _getPluginForFunction(bytes4 _functionSelector) public view returns (address) {
        PluginDataStorage.Data storage data = PluginDataStorage.pluginDataStorage();
        return data.pluginMetadata[_functionSelector].implementation;
    }

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view virtual returns (bool);
}
