// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IMap.sol";

import "../../openzeppelin-presets/utils/EnumerableSet.sol";

contract Map is IMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private allSelectors;

    mapping(address => EnumerableSet.Bytes32Set) private selectorsForPlugin;
    mapping(bytes4 => Plugin) private pluginForSelector;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(Plugin[] memory _pluginsToAdd) {
        uint256 len = _pluginsToAdd.length;
        for (uint256 i = 0; i < len; i += 1) {
            _setPlugin(_pluginsToAdd[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev View address of the plugged-in functionality contract for a given function signature.
    function getPluginForFunction(bytes4 _selector) public view returns (address) {
        address _pluginAddress = pluginForSelector[_selector].pluginAddress;
        require(_pluginAddress != address(0), "Map: No plugin available for selector");

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
    function _setPlugin(Plugin memory _plugin) internal {
        require(allSelectors.add(bytes32(_plugin.selector)), "Map: Selector exists");
        require(
            _plugin.selector == bytes4(keccak256(abi.encodePacked(_plugin.functionString))),
            "Map: Incorrect selector"
        );

        pluginForSelector[_plugin.selector] = _plugin;
        selectorsForPlugin[_plugin.pluginAddress].add(bytes32(_plugin.selector));

        emit PluginSet(_plugin.selector, _plugin.pluginAddress);
    }
}
