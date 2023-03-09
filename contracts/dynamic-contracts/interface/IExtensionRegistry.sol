// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IExtension.sol";

interface IExtensionRegistry is IExtension {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a extension is added; emitted for each function of the extension.
    event ExtensionAdded(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when extension is updated; emitted for each function of the extension.
    event ExtensionUpdated(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is removed; emitted for each function of the extension.
    event ExtensionRemoved(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when an extension is added to an extension set.
    event ExtensionSetCreated(string indexed extensionSetId, string[] extensionNames);

    /// @dev Emitted when a router is registered with a default extension set.
    event RouterRegistered(address indexed router, string indexed extensionSetId);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all extensions stored.
    function getAllExtensions() external view returns (Extension[] memory);

    /// @dev Returns all functions that belong to the given extension contract.
    function getAllFunctionsOfExtension(string memory extensionName) external view returns (ExtensionFunction[] memory);

    /// @dev Returns the extension's implementation smart contract address.
    function getExtensionImplementation(string memory extensionName) external view returns (address);

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) external view returns (Extension memory);

    /// @dev Creates a fixed set of extensions.
    function getExtensionForFunction(bytes4 _functionSelector, address _router)
        external
        view
        returns (ExtensionMetadata memory);

    /// @dev Returns all extension set IDs stored.
    function getAllExtensionSetIds() external view returns (string[] memory);

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the registry.
    function addExtension(Extension memory extension) external;

    /// @dev Updates an existing extension in the registry.
    function updateExtension(Extension memory extension) external;

    /// @dev Remove an existing extension from the registry.
    function removeExtension(string memory extension) external;

    /// @dev Registers a router contract with a default set of extensions.
    function registerRouter(string memory _extensionSetId) external;
}
