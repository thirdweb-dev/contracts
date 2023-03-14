// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IExtensionRegistry.sol";
import "lib/dynamic-contracts/src/interface/IRouter.sol";

// Lib
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";
import "../eip/ERC165.sol";

// Extensions
import "./ExtensionRegistryState.sol";
import "../extension/plugin/PermissionsEnumerableLogic.sol";

// TODO: add events emitting full `Extension` for `addExtension` and `updateExtension`.

contract ExtensionRegistry is IExtensionRegistry, ExtensionRegistryState, PermissionsEnumerableLogic {
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

    /// @notice Removes an existing extension from the contract.
    function removeExtension(string memory _extensionName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeExtension(_extensionName);
    }

    /// @notice Adds an extension to an extension snapshot.
    function buildExtensionSnapshot(
        string memory _extensionSnapshotId,
        string[] memory _extensionNames,
        bool _freeze
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(_extensionSnapshotId).length > 0, "ExtensionRegistry: extension snapshot ID cannot be empty.");

        uint256 len = _extensionNames.length;
        for (uint256 i = 0; i < len; i += 1) {
            _addExtensionToSnapshot(_extensionSnapshotId, _extensionNames[i]);
        }

        if (_freeze) {
            _freezeExtensionSnapshot(_extensionSnapshotId);
        }

        emit ExtensionSnapshotUpdated(_extensionSnapshotId, _extensionNames);
    }

    /// @dev Registers a router contract with an extension snapshot as its default set of extensions.
    function registerWithSnapshot(string memory _extensionSnapshotId) external {
        address router = msg.sender;

        bool isRouter = false;
        if (router.code.length > 0) {
            isRouter = ERC165(router).supportsInterface(type(IRouter).interfaceId);
        }
        require(isRouter, "ExtensionRegistry: caller is not a router.");

        _registerRouterWithSnapshot(_extensionSnapshotId, router);

        emit RouterRegistered(router, _extensionSnapshotId);
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
            uint256 latestId = data.nextIdForExtension[names[i]] - 1;
            allExtensions[i] = data.extensions[names[i]][latestId];
        }
    }

    /// @notice Returns the extension metadata and functions for a given extension.
    function getExtension(string memory _extensionName) public view returns (Extension memory) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        require(data.extensionNames.contains(_extensionName), "ExtensionRegistry: extension does not exist.");
        uint256 latestId = data.nextIdForExtension[_extensionName] - 1;
        return data.extensions[_extensionName][latestId];
    }

    /// @dev Returns all default extensions for a router.
    function getAllExtensionsForRouter(address router) external view returns (Extension[] memory extensions) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        string memory snapshotId = data.snapshotIdForRouter[router];
        return getExtensionSnapshot(snapshotId);
    }

    /// @dev Returns extension data for a default extension of a router.
    function getExtensionForRouter(string memory _extensionName, address _router)
        external
        view
        returns (Extension memory)
    {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        string memory snapshotId = data.snapshotIdForRouter[_router];
        require(bytes(snapshotId).length > 0, "ExtensionRegistry: router is not registered.");

        return data.extensionSnapshot[snapshotId].extension[keccak256(abi.encodePacked(_extensionName, snapshotId))];
    }

    /// @dev Returns extension metadata for the default extension associated with a function in router.
    function getExtensionForRouterFunction(bytes4 _functionSelector, address _router)
        external
        view
        returns (ExtensionMetadata memory)
    {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        string memory snapshotId = data.snapshotIdForRouter[_router];
        require(bytes(snapshotId).length > 0, "ExtensionRegistry: router is not registered.");

        return data.extensionSnapshot[snapshotId].extensionForFunction[_functionSelector];
    }

    /// @notice Returns all extension set IDs stored.
    function getAllSnapshotIds() external view returns (string[] memory) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        return data.snapshotIds.values();
    }

    /// @dev Returns all extensions stored in a snapshot.
    function getExtensionSnapshot(string memory _snapshotId) public view returns (Extension[] memory extensions) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        require(bytes(_snapshotId).length > 0, "ExtensionRegistry: extension snapshot does not exist.");

        ExtensionID[] memory extensionsIds = data.extensionSnapshot[_snapshotId].allExtensions;
        uint256 len = extensionsIds.length;

        extensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            extensions[i] = data.extensions[extensionsIds[i].name][extensionsIds[i].id];
        }
    }
}
