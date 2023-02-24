// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IExtensionRegistry.sol";

// Extensions
import "../extension/PermissionsEnumerable.sol";
import "lib/dynamic-contracts/src/presets/utils/ExtensionState.sol";
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";

contract ExtensionRegistry is IExtensionRegistry, ExtensionState, PermissionsEnumerable {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _defaultAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a new extension to the registry.
    function addExtension(Extension memory _extension) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addExtension(_extension);
    }

    /// @notice Updates an existing extension in the registry.
    function updateExtension(Extension memory _extension) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateExtension(_extension);
    }

    /// @notice Remove an existing extension from the registry.
    function removeExtension(string memory _extensionName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeExtension(_extensionName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all extensions stored.
    function getAllExtensions() external view returns (Extension[] memory allExtensions) {
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();

        string[] memory names = data.extensionNames.values();
        uint256 len = names.length;

        allExtensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allExtensions[i] = data.extensions[names[i]];
        }
    }

    /// @notice Returns the extension metadata and functions for a given extension.
    function getExtension(string memory _extensionName) public view returns (Extension memory) {
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();
        require(data.extensionNames.contains(_extensionName), "ExtensionRegistry: extension does not exist.");
        return data.extensions[_extensionName];
    }

    /// @notice Returns the extension's implementation smart contract address.
    function getExtensionImplementation(string memory _extensionName) external view returns (address) {
        return getExtension(_extensionName).metadata.implementation;
    }

    /// @notice Returns all functions that belong to the given extension contract.
    function getAllFunctionsOfExtension(string memory _extensionName)
        external
        view
        returns (ExtensionFunction[] memory)
    {
        return getExtension(_extensionName).functions;
    }

    /// @notice Returns the extension metadata for a given function.
    function getExtensionForFunction(bytes4 _functionSelector) external view returns (ExtensionMetadata memory) {
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();
        ExtensionMetadata memory metadata = data.extensionMetadata[_functionSelector];
        require(metadata.implementation != address(0), "ExtensionRegistry: no extension for function.");
        return metadata;
    }
}
