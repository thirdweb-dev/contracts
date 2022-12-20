// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IMap {
    struct Plugin {
        bytes4 selector;
        address pluginAddress;
        string functionString;
    }

    event PluginRegistered(bytes4 indexed selector, address indexed pluginAddress);

    event PluginUpdated(bytes4 indexed selector, address indexed oldPluginAddress, address indexed newPluginAddress);

    event PluginRemoved(bytes4 indexed selector, address indexed pluginAddress);

    function setPlugin(Plugin memory _plugin) external;

    function updatePlugin(Plugin memory _plugin) external;

    function removePlugin(bytes4 _selector) external;

    function getPluginForFunction(bytes4 _selector) external view returns (address);

    function getAllFunctionsOfPlugin(address _pluginAddress) external view returns (bytes4[] memory registered);

    function getAllRegistered() external view returns (Plugin[] memory registered);
}
