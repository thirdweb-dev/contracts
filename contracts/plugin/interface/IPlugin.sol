// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPlugin {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice A plugin's metadata.
     *
     *  @param name             The unique name of the plugin.
     *  @param metadataURI      The URI where the metadata for the plugin lives.
     *  @param implementation   The implementation smart contract address of the plugin.
     */
    struct PluginMetadata {
        string name;
        string metadataURI;
        address implementation;
    }

    /**
     *  @notice An interface to describe a plugin's function.
     *
     *  @param functionSelector    The 4 byte selector of the function.
     *  @param functionSignature   Function representation as a string. E.g. "transfer(address,address,uint256)"
     */
    struct PluginFunction {
        bytes4 functionSelector;
        string functionSignature;
    }

    /**
     *  @notice An interface to describe a plug-in.
     *
     *  @param metadata     The plugin's metadata; it's name, metadata URI and implementation contract address.
     *  @param functions    The functions that belong to the plugin.
     */
    struct Plugin {
        PluginMetadata metadata;
        PluginFunction[] functions;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a plugin is added; emitted for each function of the plugin.
    event PluginAdded(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature);

    /// @dev Emitted when plugin is updated; emitted for each function of the plugin.
    event PluginUpdated(
        address indexed oldPluginAddress,
        address indexed newPluginAddress,
        bytes4 indexed functionSelector,
        string functionSignature
    );

    /// @dev Emitted when a plugin is removed; emitted for each function of the plugin.
    event PluginRemoved(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature);
}
