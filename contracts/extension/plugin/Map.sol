// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IMap.sol";

import "../../openzeppelin-presets/utils/EnumerableSet.sol";

/**
 *  TODO:
 *      - Remove OZ EnumerableSet external dependency.
 */

abstract contract Map is IMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private allSelectors;

    mapping(address => EnumerableSet.Bytes32Set) private selectorsForPlugin;
    mapping(bytes4 => Plugin) private pluginForSelector;

    constructor(Plugin[] memory _pluginsToRegister) {
        uint256 len = _pluginsToRegister.length;
        for (uint256 i = 0; i < len; i += 1) {
            _setPlugin(_pluginsToRegister[i]);
        }
    }

    function setPlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "Not authorized");

        _setPlugin(_plugin);
    }

    function updatePlugin(Plugin memory _plugin) external {
        require(_canSetPlugin(), "Not authorized");

        _updatePlugin(_plugin);
    }

    function removePlugin(bytes4 _selector) external {
        require(_canSetPlugin(), "Not authorized");

        _removePlugin(_selector);
    }

    function _setPlugin(Plugin memory _plugin) internal {
        require(allSelectors.add(bytes32(_plugin.selector)), "REGISTERED");
        require(_plugin.selector == bytes4(keccak256(abi.encodePacked(_plugin.functionString))), "Incorrect selector");

        pluginForSelector[_plugin.selector] = _plugin;
        selectorsForPlugin[_plugin.pluginAddress].add(bytes32(_plugin.selector));

        emit PluginRegistered(_plugin.selector, _plugin.pluginAddress);
    }

    function _updatePlugin(Plugin memory _plugin) internal {
        address currentExtension = getPluginForFunction(_plugin.selector);
        require(_plugin.selector == bytes4(keccak256(abi.encodePacked(_plugin.functionString))), "Incorrect selector");

        pluginForSelector[_plugin.selector] = _plugin;
        selectorsForPlugin[_plugin.pluginAddress].add(bytes32(_plugin.selector));
        selectorsForPlugin[currentExtension].remove(bytes32(_plugin.selector));

        emit PluginUpdated(_plugin.selector, currentExtension, _plugin.pluginAddress);
    }

    function _removePlugin(bytes4 _selector) internal {
        address currentExtension = getPluginForFunction(_selector);

        delete pluginForSelector[_selector];
        allSelectors.remove(_selector);
        selectorsForPlugin[currentExtension].remove(bytes32(_selector));

        emit PluginRemoved(_selector, currentExtension);
    }

    function getPluginForFunction(bytes4 _selector) public view returns (address) {
        address _pluginAddress = pluginForSelector[_selector].pluginAddress;
        require(_pluginAddress != address(0), "No plugin available for selector.");

        return _pluginAddress;
    }

    function getAllFunctionsOfPlugin(address _extension) external view returns (bytes4[] memory registered) {
        uint256 len = selectorsForPlugin[_extension].length();
        registered = new bytes4[](len);

        for (uint256 i = 0; i < len; i += 1) {
            registered[i] = bytes4(selectorsForPlugin[_extension].at(i));
        }
    }

    function getAllRegistered() external view returns (Plugin[] memory functionExtensionPairs) {
        uint256 len = allSelectors.length();
        functionExtensionPairs = new Plugin[](len);

        for (uint256 i = 0; i < len; i += 1) {
            bytes4 selector = bytes4(allSelectors.at(i));
            functionExtensionPairs[i] = pluginForSelector[selector];
        }
    }

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view virtual returns (bool);
}
