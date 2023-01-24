// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../PermissionsEnumerable.sol";
import "../interface/plugin/IPluginRegistry.sol";
import "../../openzeppelin-presets/utils/EnumerableSet.sol";

contract PluginRegistry is IPluginRegistry, PermissionsEnumerable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    EnumerableSet.Bytes32Set private allSelectors;

    mapping(address => EnumerableSet.Bytes32Set) private selectorsForPlugin;
    mapping(bytes4 => Plugin) private pluginForSelector;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _defaultAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Add functionality to the contract.
    function addPlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "PluginRegistry: Not authorized");

        _addPlugin(_plugin);
    }

    /// @dev Update or override existing functionality.
    function updatePlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "PluginRegistry: Not authorized");

        _updatePlugin(_plugin);
    }

    /// @dev Remove existing functionality from the contract.
    function removePlugin(bytes4 _selector) external {
        require(_canSetPlugin(), "PluginRegistry: Not authorized");

        _removePlugin(_selector);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin exists in the Plugin registry.
    function isApprovedPlugin(bytes4 functionSelector, address _plugin) external view returns (bool) {
        address pluginAddress = pluginForSelector[functionSelector].pluginAddress;
        return pluginAddress != address(0) && pluginAddress == _plugin;
    }

    /// @dev View address of the plugged-in functionality contract for a given function signature.
    function getPluginForFunction(bytes4 _selector) public view returns (address) {
        address _pluginAddress = pluginForSelector[_selector].pluginAddress;
        require(_pluginAddress != address(0), "PluginRegistry: No plugin available for selector");

        return _pluginAddress;
    }

    /// @dev View all funtionality as list of function signatures.
    function getAllFunctionsOfPlugin(address _pluginAddress) external view returns (bytes4[] memory registered) {
        uint256 len = selectorsForPlugin[_pluginAddress].length();
        registered = new bytes4[](len);

        for (uint256 i = 0; i < len; i += 1) {
            registered[i] = bytes4(selectorsForPlugin[_pluginAddress].at(i));
        }
    }

    /// @dev View all funtionality existing on the contract.
    function getAllPlugins() external view returns (Plugin[] memory _plugins) {
        uint256 len = allSelectors.length();
        _plugins = new Plugin[](len);

        for (uint256 i = 0; i < len; i += 1) {
            bytes4 selector = bytes4(allSelectors.at(i));
            _plugins[i] = pluginForSelector[selector];
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Add functionality to the contract.
    function _addPlugin(Plugin memory _plugin) internal {
        require(allSelectors.add(bytes32(_plugin.functionSelector)), "PluginRegistry: plugin exists for function.");

        require(
            _plugin.functionSelector == bytes4(keccak256(abi.encodePacked(_plugin.functionSignature))),
            "PluginRegistry: fn selector and signature mismatch."
        );

        pluginForSelector[_plugin.functionSelector] = _plugin;
        selectorsForPlugin[_plugin.pluginAddress].add(bytes32(_plugin.functionSelector));

        emit PluginAdded(_plugin.functionSelector, _plugin.pluginAddress);
    }

    /// @dev Update or override existing functionality.
    function _updatePlugin(Plugin memory _plugin) internal {
        address currentPlugin = getPluginForFunction(_plugin.functionSelector);

        require(currentPlugin != _plugin.pluginAddress, "PluginRegistry: Re-adding existing plugin.");
        require(
            _plugin.functionSelector == bytes4(keccak256(abi.encodePacked(_plugin.functionSignature))),
            "PluginRegistry: fn selector and signature mismatch."
        );

        pluginForSelector[_plugin.functionSelector] = _plugin;
        selectorsForPlugin[currentPlugin].remove(bytes32(_plugin.functionSelector));
        selectorsForPlugin[_plugin.pluginAddress].add(bytes32(_plugin.functionSelector));

        emit PluginUpdated(_plugin.functionSelector, currentPlugin, _plugin.pluginAddress);
    }

    /// @dev Remove existing functionality from the contract.
    function _removePlugin(bytes4 _selector) internal {
        address currentPlugin = pluginForSelector[_selector].pluginAddress;
        require(currentPlugin != address(0), "PluginRegistry: No plugin available for selector");

        pluginForSelector[_selector];
        allSelectors.remove(_selector);
        selectorsForPlugin[currentPlugin].remove(bytes32(_selector));

        emit PluginRemoved(_selector, currentPlugin);
    }

    function _canSetPlugin() internal view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
