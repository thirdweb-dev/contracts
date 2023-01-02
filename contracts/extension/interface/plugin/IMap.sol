// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IMap {
    /**
     *  @notice An interface to describe a plug-in functionality.
     *
     *  @param selector         4-byte function signature.
     *  @param pluginAddress    Address of the contract containing the function.
     *  @param functionString   Function representation as a string. E.g. "transfer(address,address,uint256)"
     */
    struct Plugin {
        bytes4 selector;
        address pluginAddress;
        string functionString;
    }

    /// @dev Emitted when a functionality is set, or plugged-in, during construction of Map.
    event PluginSet(bytes4 indexed selector, address indexed pluginAddress);

    /// @dev View address of the plugged-in functionality contract for a given function signature.
    function getPluginForFunction(bytes4 _selector) external view returns (address);

    /// @dev View all funtionality as list of function signatures.
    function getAllFunctionsOfPlugin(address _pluginAddress) external view returns (bytes4[] memory);

    /// @dev View all funtionality existing on the contract.
    function getAllPlugins() external view returns (Plugin[] memory);
}
