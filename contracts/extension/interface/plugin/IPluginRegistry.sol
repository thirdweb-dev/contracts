// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPluginRegistry {
    /*///////////////////////////////////////////////////////////////
                                Structs
    ///////////////////////////////////////////////////////////////*/

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
     *  @param functionSelector The 4 byte selector of the function.
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

    /// @dev Emitted when a functionality is added, or plugged-in.
    event PluginAdded(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature);

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

    /// @dev Add a new plugin to the registry.
    function addPlugin(Plugin memory plugin) external;

    /// @dev Update / override an existing plugin.
    function updatePlugin(Plugin memory plugin) external;

    /// @dev Remove an existing plugin from the registry.
    function removePlugin(string memory plugin) external;

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin exists in the Plugin registry.
    function isApprovedPlugin(bytes4 functionSelector, address plugin) external view returns (bool);

    /// @dev Returns the metadata of all registered plugins.
    function getAllPluginMetadata() external view returns (PluginMetadata[] memory plugins);

    /// @dev Returns all plugins registererd in the registry.
    function getAllPlugins() external view returns (Plugin[] memory plugins);

    /// @dev Returns all functions belonging to the given plugin.
    function getAllFunctionsOfPlugin(string memory plugin)
        external
        view
        returns (PluginFunction[] memory functions, address pluginAddress);

    /// @dev Returns the plugin contract for a given function.
    function getPluginForFunction(bytes4 functionSelector) external view returns (address pluginAddress);

    /// @dev Returns the plugin metadata for a given function.
    function getPluginMetadataForFunction(bytes4 functionSelector)
        external
        view
        returns (PluginMetadata memory metadata);
}
