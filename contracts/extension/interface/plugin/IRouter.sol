// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPluginMap.sol";

interface IRouter is IPluginMap {
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
