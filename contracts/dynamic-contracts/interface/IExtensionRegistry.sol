// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IExtensionRegistryState.sol";
import "./IExtensionRegistrySig.sol";

interface IExtensionRegistry is IExtensionRegistryState, IExtensionRegistrySig {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a extension is added.
    event ExtensionAdded(string indexed name, address indexed implementation, Extension extension);

    /// @notice Emitted when extension is updated.
    event ExtensionUpdated(string indexed name, address indexed implementation, Extension extension);

    /// @notice Emitted when an extension is removed.
    event ExtensionRemoved(string indexed extensionName);

    /// @notice Emitted when a default set of extensions is associated with a contract type.
    event ExtensionSetForContractType(string indexed contractType, string[] extensionNames);

    /// @notice Emitted when a contract is registered with a contract type.
    event ContractRegistered(address indexed targetContract, string indexed contractType);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all extensions stored in the registry.
    function getAllExtensions() external view returns (Extension[] memory);

    /// @notice Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) external view returns (Extension memory);

    /// @notice Returns all default extensions for a contract.
    function getAllDefaultExtensionsForContract(address router) external view returns (Extension[] memory);

    /// @notice Returns extension data for a default extension of a contract.
    function getDefaultExtensionForContract(string memory _extensionName, address _contract)
        external
        view
        returns (Extension memory);

    /// @notice Returns extension metadata for the default extension associated with a function in a contract.
    function getExtensionForContractFunction(bytes4 functionSelector, address router)
        external
        view
        returns (ExtensionMetadata memory);

    /// @notice Returns all contract types stored in the registry.
    function getAllContractTypes() external view returns (string[] memory);

    /// @notice Returns the latest state of all extensions that belong to a contract type.
    function getLatestExtensionsForContractType(string memory contractType) external view returns (Extension[] memory);

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a new extension to the registry.
    function addExtension(Extension memory extension) external;

    /// @notice Adds a new extension to the registry via an authorized signature.
    function addExtensionWithSig(
        Extension memory extension,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @notice Updates an existing extension in the registry.
    function updateExtension(Extension memory extension) external;

    /// @notice Updates an existing extension in the registry via an authorized signature.
    function updateExtensionWithSig(
        Extension memory extension,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @notice Removes an existing extension from the registry.
    function removeExtension(string memory extensionName) external;

    /// @notice Removes an existing extension from the registry via an authorized signature.
    function removeExtensionWithSig(
        string memory extensionName,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @notice Sets what extensions belong to the given contract type.
    function setExtensionsForContractType(string memory contractType, string[] memory extensionNames) external;

    /// @notice Sets what extensions belong to the given contract type via an authorized signature.
    function setExtensionsForContractTypeWithSig(
        string memory contractType,
        string[] memory extensionNames,
        ExtensionUpdateRequest calldata req,
        bytes calldata signature
    ) external;

    /// @notice Registers a contract with a contract type.
    function registerContract(string memory contractType) external;
}
