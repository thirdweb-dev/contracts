// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPluginMap.sol";

interface IRouterPrev is IPluginMap {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a functionality is updated or overridden.
    event PluginUpdated(
        address indexed oldPluginAddress,
        address indexed newPluginAddress,
        bytes4 indexed functionSelector,
        string functionSignature
    );

    /// @dev Emitted when a functionality is removed.
    event PluginRemoved(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature);

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Add a new plugin to the contract.
    function addPlugin(string memory pluginName) external;

    /// @dev Update / override an existing plugin.
    function updatePlugin(string memory pluginName) external;

    /// @dev Remove an existing plugin from the contract.
    function removePlugin(string memory pluginName) external;
}
