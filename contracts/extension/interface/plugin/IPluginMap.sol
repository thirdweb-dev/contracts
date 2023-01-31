// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPlugin.sol";

interface IPluginMap is IPlugin {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a function selector is mapped to a particular plug-in smart contract, during construction of Map.
    event PluginAdded(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the plug-in metadata for a given function.
    function getPluginForFunction(bytes4 functionSelector) external view returns (PluginMetadata memory);

    /// @dev Returns all functions that are mapped to the given plug-in contract.
    function getAllFunctionsOfPlugin(address pluginAddress) external view returns (PluginFunction[] memory);

    /// @dev Returns all plug-ins known by Map.
    function getAllPlugins() external view returns (Plugin[] memory);
}
