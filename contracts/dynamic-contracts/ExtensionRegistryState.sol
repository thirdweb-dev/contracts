// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IExtensionRegistryState.sol";

// Extensions
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";

library ExtensionRegistryStateStorage {
    bytes32 public constant EXTENSION_REGISTRY_STATE_STORAGE_POSITION = keccak256("extension.registry.state.storage");

    struct Data {
        // ====== Extensions ======

        /// @dev Set of names of all extensions stored.
        StringSet.Set extensionNames;
        /// @dev Mapping from extension name => next ID to use for extension.
        mapping(string => uint256) nextIdForExtension;
        /// @dev Mapping from extension name => ID for extension => `Extension` i.e. extension metadata and functions.
        mapping(string => mapping(uint256 => IExtension.Extension)) extensions;
        // ====== Extension Sets ======

        /// @dev Set of all extension snapshot IDs.
        StringSet.Set snapshotIds;
        /// @dev Mapping from router contract address => snapshot ID for router's default set of extensions.
        mapping(address => string) snapshotIdForRouter;
        /// @dev Mapping from snapshot ID => extension snapshot.
        mapping(string => IExtensionRegistryState.ExtensionSnapshotData) extensionSnapshot;
    }

    function extensionRegistryStateStorage() internal pure returns (Data storage extensionRegistryStateData) {
        bytes32 position = EXTENSION_REGISTRY_STATE_STORAGE_POSITION;
        assembly {
            extensionRegistryStateData.slot := position
        }
    }
}

contract ExtensionRegistryState is IExtensionRegistryState {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                    Internal functions: extension sets
    //////////////////////////////////////////////////////////////*/

    function _addExtensionToSnapshot(string memory _snapshotId, string memory _extensionName) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        require(data.extensionNames.contains(_extensionName), "ExtensionRegistryState: extension does not exist.");
        require(!data.extensionSnapshot[_snapshotId].isFrozen, "ExtensionRegistryState: extension snapshot is frozen.");

        uint256 latestId = data.nextIdForExtension[_extensionName] - 1;
        Extension memory extension = data.extensions[_extensionName][latestId];

        bytes32 nameHash = keccak256(abi.encodePacked(_extensionName, _snapshotId));
        data.extensionSnapshot[_snapshotId].extension[nameHash].metadata = extension.metadata;
        data.extensionSnapshot[_snapshotId].allExtensions.push(ExtensionID({ name: _extensionName, id: latestId }));

        uint256 len = extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                data
                    .extensionSnapshot[_snapshotId]
                    .extensionForFunction[extension.functions[i].functionSelector]
                    .implementation == address(0),
                "ExtensionRegistryState: function already exists in snapshot."
            );

            data.extensionSnapshot[_snapshotId].extensionForFunction[
                extension.functions[i].functionSelector
            ] = extension.metadata;

            data.extensionSnapshot[_snapshotId].extension[nameHash].functions.push(extension.functions[i]);
        }
    }

    function _registerRouterWithSnapshot(string memory _snapshotId, address _router) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        require(data.snapshotIds.contains(_snapshotId), "ExtensionRegistry: extension set does not exist.");

        require(bytes(data.snapshotIdForRouter[_router]).length == 0, "ExtensionRegistry: router already registered.");

        data.snapshotIdForRouter[_router] = _snapshotId;
    }

    function _freezeExtensionSnapshot(string memory _snapshotId) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        data.extensionSnapshot[_snapshotId].isFrozen = true;
    }

    /*///////////////////////////////////////////////////////////////
        Internal functions: add/update extensions in global map
    //////////////////////////////////////////////////////////////*/

    /// @dev Stores a new extension in the contract.
    function _addExtension(Extension memory _extension) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        string memory name = _extension.metadata.name;
        require(bytes(name).length > 0, "ExtensionRegistryState: adding extension without name.");
        require(data.extensionNames.add(name), "ExtensionRegistryState: extension already exists.");
        uint256 nextId = data.nextIdForExtension[name];
        data.nextIdForExtension[name] += 1;

        data.extensions[name][nextId].metadata = _extension.metadata;

        require(
            _extension.metadata.implementation != address(0),
            "ExtensionRegistryState: adding extension without implementation."
        );

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _extension.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature))),
                "ExtensionRegistryState: fn selector and signature mismatch."
            );

            data.extensions[name][nextId].functions.push(_extension.functions[i]);

            emit ExtensionAdded(
                _extension.metadata.implementation,
                _extension.functions[i].functionSelector,
                _extension.functions[i].functionSignature
            );
        }
    }

    /// @dev Updates / overrides an existing extension in the contract.
    function _updateExtension(Extension memory _extension) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        string memory name = _extension.metadata.name;
        require(data.extensionNames.contains(name), "ExtensionRegistryState: extension does not exist.");

        uint256 nextId = data.nextIdForExtension[name];
        data.nextIdForExtension[name] += 1;

        address oldImplementation = data.extensions[name][nextId - 1].metadata.implementation;
        require(
            _extension.metadata.implementation != oldImplementation,
            "ExtensionRegistryState: re-adding same extension."
        );

        data.extensions[name][nextId].metadata = _extension.metadata;

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _extension.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature))),
                "ExtensionRegistryState: fn selector and signature mismatch."
            );

            data.extensions[name][nextId].functions.push(_extension.functions[i]);

            emit ExtensionUpdated(
                oldImplementation,
                _extension.metadata.implementation,
                _extension.functions[i].functionSelector,
                _extension.functions[i].functionSignature
            );
        }
    }

    /// @dev Removes an existing extension from the contract.
    function _removeExtension(string memory _extensionName) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        uint256 latestId = data.nextIdForExtension[_extensionName] - 1;
        Extension memory extension = data.extensions[_extensionName][latestId];

        require(data.extensionNames.remove(_extensionName), "ExtensionState: extension does not exist.");

        emit ExtensionRemoved(_extensionName, extension);
    }
}
