// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IExtensionRegistry.sol";

// Extensions
import "../extension/PermissionsEnumerable.sol";
import "./ExtensionRegistryState.sol";
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";

contract ExtensionRegistry is IExtensionRegistry, ExtensionRegistryState, PermissionsEnumerable {
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

    /// @notice Adds an extension to an extension set.
    function createExtensionSet(string memory _extensionSetId, string[] memory _extensionNames)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(_extensionSetId).length > 0, "ExtensionRegistry: extension set ID cannot be empty.");
        require(!_extensionSetExists(_extensionSetId), "ExtensionRegistry: extension set already exists.");

        uint256 len = _extensionNames.length;
        for (uint256 i = 0; i < len; i += 1) {
            _addExtensionToSet(_extensionSetId, _extensionNames[i]);
        }

        emit ExtensionSetCreated(_extensionSetId, _extensionNames);
    }

    /// @notice Registers a router contract with a default set of extensions.
    function registerRouter(string memory _extensionSetId) external {
        address router = msg.sender;
        _registerRouter(_extensionSetId, router);
        emit RouterRegistered(router, _extensionSetId);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all extensions stored.
    function getAllExtensions() external view returns (Extension[] memory allExtensions) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        string[] memory names = data.extensionNames.values();
        uint256 len = names.length;

        allExtensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allExtensions[i] = data.extensions[names[i]];
        }
    }

    /// @notice Returns the extension metadata and functions for a given extension.
    function getExtension(string memory _extensionName) public view returns (Extension memory) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
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

    /// @notice Returns all extension set IDs stored.
    function getAllExtensionSetIds() external view returns (string[] memory) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        return data.extensionSetIds.values();
    }

    /// @notice Returns the extension metadata and functions for a given function selector.
    function getExtensionForFunction(bytes4 _functionSelector, address _router)
        external
        view
        returns (ExtensionMetadata memory)
    {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        string memory id = data.defaultExtensionSetId[_router];
        return data.implementationForFunction[id][_functionSelector];
    }
}
