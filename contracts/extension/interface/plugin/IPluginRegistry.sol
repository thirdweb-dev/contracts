// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPluginRegistry {
    /**
     *  @notice An interface to describe a plug-in.
     *
     *  @param functionSelector     4-byte function selector.
     *  @param functionSignature    Function representation as a string. E.g. "transfer(address,address,uint256)"
     *  @param pluginAddress        Address of the contract containing the function.
     */
    struct Plugin {
        bytes4 functionSelector;
        string functionSignature;
        address pluginAddress;
    }

    /// @dev Emitted when a function selector is mapped to a particular plug-in smart contract, during construction of Map.
    event PluginSet(bytes4 indexed functionSelector, string indexed functionSignature, address indexed pluginAddress);

    /// @dev Emitted when a functionality is added, or plugged-in.
    event PluginAdded(bytes4 indexed functionSelector, address indexed pluginAddress);

    /// @dev Emitted when a functionality is updated or overridden.
    event PluginUpdated(
        bytes4 indexed functionSelector,
        address indexed oldPluginAddress,
        address indexed newPluginAddress
    );

    /// @dev Emitted when a functionality is removed.
    event PluginRemoved(bytes4 indexed functionSelector, address indexed pluginAddress);

    /// @dev Returns the plug-in contract for a given function.
    function getPluginForFunction(bytes4 functionSelector) external view returns (address);

    /// @dev Returns all functions that are mapped to the given plug-in contract.
    function getAllFunctionsOfPlugin(address pluginAddress) external view returns (bytes4[] memory);

    /// @dev Returns all plug-ins known by Map.
    function getAllPlugins() external view returns (Plugin[] memory);

    /// @dev Returns whether a plugin exists in the Plugin registry.
    function isApprovedPlugin(bytes4 functionSelector, address plugin) external view returns (bool);

    /// @dev Add a new plugin to the registry.
    function addPlugin(Plugin memory plugin) external;

    /// @dev Update / override an existing plugin.
    function updatePlugin(Plugin memory plugin) external;

    /// @dev Remove an existing plugin from the registry.
    function removePlugin(bytes4 functionSelector) external;
}
