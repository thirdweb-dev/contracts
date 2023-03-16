// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IExtensionRegistryState.sol";
import "./IExtensionRegistrySig.sol";

interface IExtensionRegistry is IExtensionRegistryState, IExtensionRegistrySig {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a extension is added; emitted for each function of the extension.
    event ExtensionAdded(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when extension is updated; emitted for each function of the extension.
    event ExtensionUpdated(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when an extension is added to an extension snapshot.
    event ExtensionSnapshotUpdated(string indexed extensionSnapshotId, string[] extensionNames);

    /// @dev Emitted when a router is registered with a default extension set.
    event RouterRegistered(address indexed router, string indexed extensionSnapshotId);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all extensions stored.
    function getAllExtensions() external view returns (Extension[] memory);

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) external view returns (Extension memory);

    /// @dev Returns all default extensions for a router.
    function getAllExtensionsForRouter(address router) external view returns (Extension[] memory);

    /// @dev Returns extension data for a default extension of a router.
    function getExtensionForRouter(string memory extensionName, address router)
        external
        view
        returns (Extension memory);

    /// @dev Returns extension metadata for the default extension associated with a function in router.
    function getExtensionForRouterFunction(bytes4 functionSelector, address router)
        external
        view
        returns (ExtensionMetadata memory);

    /// @dev Returns unique IDs of each extension snapshot.
    function getAllSnapshotIds() external view returns (string[] memory);

    /// @dev Returns all extensions stored in a snapshot.
    function getExtensionSnapshot(string memory snapshotId) external view returns (Extension[] memory);

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the registry.
    function addExtension(Extension memory extension) external;

    /// @dev Adds a new extension to the registry.
    function addExtensionWithSig(
        Extension memory extension,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @dev Updates an existing extension in the registry.
    function updateExtension(Extension memory extension) external;

    /// @dev Updates an existing extension in the registry.
    function updateExtensionWithSig(
        Extension memory extension,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @notice Removes an existing extension from the contract.
    function removeExtension(string memory extensionName) external;

    /// @notice Removes an existing extension from the contract.
    function removeExtensionWithSig(
        string memory extensionName,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @notice Adds an extension to an extension snapshot.
    function buildExtensionSnapshot(
        string memory extensionSnapshotId,
        string[] memory extensionNames,
        bool freeze
    ) external;

    /// @notice Adds an extension to an extension snapshot.
    function buildExtensionSnapshotWithSig(
        string memory extensionSnapshotId,
        string[] memory extensionNames,
        bool freeze,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @dev Registers a router contract with an extension snapshot as its default set of extensions.
    function registerWithSnapshot(string memory extensionSnapshotId) external;
}
