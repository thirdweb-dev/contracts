// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "lib/dynamic-contracts/src/interface/IExtension.sol";

// Extensions
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";

library ExtensionRegistryStateStorage {
    bytes32 public constant EXTENSION_REGISTRY_STATE_STORAGE_POSITION = keccak256("extension.registry.state.storage");

    struct Data {
        // ====== Extensions ======

        /// @dev Set of names of all extensions stored.
        StringSet.Set extensionNames;
        /// @dev Mapping from extension name => `Extension` i.e. extension metadata and functions.
        mapping(string => IExtension.Extension) extensions;
        // ====== Extension Sets ======

        /// @dev Set of IDs for extension sets.
        StringSet.Set extensionSetIds;
        /// @dev Mapping from router contract address => ID for router's default extension set.
        mapping(address => string) defaultExtensionSetId;
        /// @dev Mapping from function selector => extensionSetId => `Extension` i.e. extension metadata and functions.
        mapping(string => mapping(bytes4 => IExtension.ExtensionMetadata)) implementationForFunction;
    }

    function extensionRegistryStateStorage() internal pure returns (Data storage extensionRegistryStateData) {
        bytes32 position = EXTENSION_REGISTRY_STATE_STORAGE_POSITION;
        assembly {
            extensionRegistryStateData.slot := position
        }
    }
}

contract ExtensionRegistryState is IExtension {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function _registerRouter(string memory _extensionSetId, address _router) internal {
        require(_extensionSetExists(_extensionSetId), "ExtensionRegistry: extension set does not exist.");
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        require(
            bytes(data.defaultExtensionSetId[_router]).length == 0,
            "ExtensionRegistry: router already registered."
        );

        data.defaultExtensionSetId[_router] = _extensionSetId;
    }

    function _extensionSetExists(string memory _extensionSetId) internal view returns (bool) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        return data.extensionSetIds.contains(_extensionSetId);
    }

    function _addExtensionToSet(string memory _extensionSetId, string memory _extensionName) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        require(data.extensionNames.contains(_extensionName), "ExtensionRegistryState extension does not exist.");

        Extension memory extension = data.extensions[_extensionName];
        uint256 len = extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                data
                .implementationForFunction[_extensionSetId][extension.functions[i].functionSelector].implementation ==
                    address(0),
                "ExtensionRegistryState: function already exists in set."
            );

            data.implementationForFunction[_extensionSetId][extension.functions[i].functionSelector] = extension
                .metadata;
        }
    }

    /// @dev Stores a new extension in the contract.
    function _addExtension(Extension memory _extension) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        string memory name = _extension.metadata.name;

        require(data.extensionNames.add(name), "ExtensionRegistryState extension already exists.");
        data.extensions[name].metadata = _extension.metadata;

        require(
            _extension.metadata.implementation != address(0),
            "ExtensionRegistryState adding extension without implementation."
        );

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _extension.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature))),
                "ExtensionRegistryState fn selector and signature mismatch."
            );

            data.extensions[name].functions.push(_extension.functions[i]);

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
        require(data.extensionNames.contains(name), "ExtensionRegistryState extension does not exist.");

        address oldImplementation = data.extensions[name].metadata.implementation;
        require(
            _extension.metadata.implementation != oldImplementation,
            "ExtensionRegistryState re-adding same extension."
        );

        data.extensions[name].metadata = _extension.metadata;

        delete data.extensions[name].functions;

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _extension.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature))),
                "ExtensionRegistryState fn selector and signature mismatch."
            );

            data.extensions[name].functions.push(_extension.functions[i]);

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

        require(data.extensionNames.remove(_extensionName), "ExtensionRegistryState extension does not exist.");

        address implementation = data.extensions[_extensionName].metadata.implementation;
        ExtensionFunction[] memory extensionFunctions = data.extensions[_extensionName].functions;
        delete data.extensions[_extensionName];

        uint256 len = extensionFunctions.length;
        for (uint256 i = 0; i < len; i += 1) {
            emit ExtensionRemoved(
                implementation,
                extensionFunctions[i].functionSelector,
                extensionFunctions[i].functionSignature
            );
        }
    }
}
