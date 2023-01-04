// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IRouter.sol";
import "../../extension/Multicall.sol";
import "../../eip/ERC165.sol";
import "../../openzeppelin-presets/utils/EnumerableSet.sol";

library RouterStorage {
    bytes32 public constant ROUTER_STORAGE_POSITION = keccak256("router.storage");

    struct Data {
        EnumerableSet.Bytes32Set allSelectors;
        mapping(address => EnumerableSet.Bytes32Set) selectorsForPlugin;
        mapping(bytes4 => IPluginMap.Plugin) pluginForSelector;
    }

    function routerStorage() internal pure returns (Data storage routerData) {
        bytes32 position = ROUTER_STORAGE_POSITION;
        assembly {
            routerData.slot := position
        }
    }
}

abstract contract Router is Multicall, ERC165, IRouter {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    address public immutable functionMap;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _functionMap) {
        functionMap = _functionMap;
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
            _pluginAddress = IPluginMap(functionMap).getPluginForFunction(msg.sig);
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
    function addPlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "Router: Not authorized");

        _addPlugin(_plugin);
    }

    /// @dev Update or override existing functionality.
    function updatePlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "Map: Not authorized");

        _updatePlugin(_plugin);
    }

    /// @dev Remove existing functionality from the contract.
    function removePlugin(bytes4 _selector) external {
        require(_canSetPlugin(), "Map: Not authorized");

        _removePlugin(_selector);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev View address of the plugged-in functionality contract for a given function signature.
    function getPluginForFunction(bytes4 _selector) public view returns (address) {
        address _pluginAddress = _getPluginForFunction(_selector);

        return _pluginAddress != address(0) ? _pluginAddress : IPluginMap(functionMap).getPluginForFunction(_selector);
    }

    /// @dev View all funtionality as list of function signatures.
    function getAllFunctionsOfPlugin(address _pluginAddress) external view returns (bytes4[] memory registered) {
        RouterStorage.Data storage data = RouterStorage.routerStorage();
        EnumerableSet.Bytes32Set storage _selectorsForPlugin = data.selectorsForPlugin[_pluginAddress];
        bytes4[] memory _defaultSelectors = IPluginMap(functionMap).getAllFunctionsOfPlugin(_pluginAddress);
        uint256 len = _defaultSelectors.length;
        uint256 count = _selectorsForPlugin.length() + _defaultSelectors.length;

        for (uint256 i = 0; i < len; i += 1) {
            if (_selectorsForPlugin.contains(_defaultSelectors[i])) {
                count -= 1;
                _defaultSelectors[i] = bytes4(0);
            }
        }

        registered = new bytes4[](count);
        uint256 index;

        for (uint256 i = 0; i < len; i += 1) {
            if (_defaultSelectors[i] != bytes4(0)) {
                registered[index++] = _defaultSelectors[i];
            }
        }

        len = _selectorsForPlugin.length();
        for (uint256 i = 0; i < len; i += 1) {
            registered[index++] = bytes4(data.selectorsForPlugin[_pluginAddress].at(i));
        }
    }

    /// @dev View all funtionality existing on the contract.
    function getAllPlugins() external view returns (Plugin[] memory registered) {
        RouterStorage.Data storage data = RouterStorage.routerStorage();
        uint256 len = data.allSelectors.length();

        EnumerableSet.Bytes32Set storage _allSelectors = data.allSelectors;
        Plugin[] memory _defaultPlugins = IPluginMap(functionMap).getAllPlugins();

        uint256 count = _allSelectors.length() + _defaultPlugins.length;
        for (uint256 i = 0; i < _allSelectors.length(); i += 1) {
            for (uint256 j = 0; j < _defaultPlugins.length; j += 1) {
                if (bytes4(_allSelectors.at(i)) == _defaultPlugins[j].functionSelector) {
                    count -= 1;
                    _defaultPlugins[j].functionSelector = bytes4(0);
                }
            }
        }

        registered = new Plugin[](count);
        uint256 index;

        len = _defaultPlugins.length;
        for (uint256 i = 0; i < len; i += 1) {
            if (_defaultPlugins[i].functionSelector != bytes4(0)) {
                registered[index++] = _defaultPlugins[i];
            }
        }

        len = _allSelectors.length();
        for (uint256 i = 0; i < len; i += 1) {
            registered[index++] = data.pluginForSelector[bytes4(_allSelectors.at(i))];
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev View address of the plugged-in functionality contract for a given function signature.
    function _getPluginForFunction(bytes4 _selector) public view returns (address) {
        RouterStorage.Data storage data = RouterStorage.routerStorage();
        address _pluginAddress = data.pluginForSelector[_selector].pluginAddress;

        return _pluginAddress;
    }

    /// @dev Add functionality to the contract.
    function _addPlugin(Plugin memory _plugin) internal {
        RouterStorage.Data storage data = RouterStorage.routerStorage();

        // Revert: default plugin exists for function; use updatePlugin instead.
        try IPluginMap(functionMap).getPluginForFunction(_plugin.functionSelector) returns (address) {
            revert("Router: default plugin exists for function.");
        } catch {
            require(data.allSelectors.add(bytes32(_plugin.functionSelector)), "Router: plugin exists for function.");
        }

        require(
            _plugin.functionSelector == bytes4(keccak256(abi.encodePacked(_plugin.functionSignature))),
            "Router: fn selector and signature mismatch."
        );

        data.pluginForSelector[_plugin.functionSelector] = _plugin;
        data.selectorsForPlugin[_plugin.pluginAddress].add(bytes32(_plugin.functionSelector));

        emit PluginAdded(_plugin.functionSelector, _plugin.pluginAddress);
    }

    /// @dev Update or override existing functionality.
    function _updatePlugin(Plugin memory _plugin) internal {
        RouterStorage.Data storage data = RouterStorage.routerStorage();
        address currentPlugin = _getPluginForFunction(_plugin.functionSelector);
        require(currentPlugin != address(0), "Router: No plugin available for selector");
        require(
            _plugin.functionSelector == bytes4(keccak256(abi.encodePacked(_plugin.functionSignature))),
            "Router: fn selector and signature mismatch."
        );

        data.pluginForSelector[_plugin.functionSelector] = _plugin;
        data.selectorsForPlugin[currentPlugin].remove(bytes32(_plugin.functionSelector));
        data.selectorsForPlugin[_plugin.pluginAddress].add(bytes32(_plugin.functionSelector));

        emit PluginUpdated(_plugin.functionSelector, currentPlugin, _plugin.pluginAddress);
    }

    /// @dev Remove existing functionality from the contract.
    function _removePlugin(bytes4 _selector) internal {
        RouterStorage.Data storage data = RouterStorage.routerStorage();
        address currentPlugin = _getPluginForFunction(_selector);
        require(currentPlugin != address(0), "Router: No plugin available for selector");

        delete data.pluginForSelector[_selector];
        data.allSelectors.remove(_selector);
        data.selectorsForPlugin[currentPlugin].remove(bytes32(_selector));

        emit PluginRemoved(_selector, currentPlugin);
    }

    function _canSetPlugin() internal view virtual returns (bool);
}
