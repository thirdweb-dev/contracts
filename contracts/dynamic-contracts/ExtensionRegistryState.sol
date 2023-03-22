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
        /// @dev Mapping from function selector => Extension ID hash i.e. keccak256(extension name, ID) => extension metadata.
        mapping(bytes4 => mapping(bytes32 => IExtension.ExtensionMetadata)) extensionForFunction;
        // ====== Extension Sets ======

        /// @dev Set of all contract types stored.
        StringSet.Set allContractTypes;
        /// @dev Mapping from contract type => extension names of extensions for contract type.
        mapping(string => StringSet.Set) extensionsForContractType;
        /// @dev Mapping from contract address => fixed default extensions for contract.
        mapping(address => IExtensionRegistryState.ExtensionID[]) defaultExtensionsForContract;
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

    function _setExtensionsForContractType(string memory _contractType, string[] memory _extensionNames) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        data.allContractTypes.add(_contractType);

        // Instead of: `delete data.extensionsForContractType[_contractType];`
        string[] memory currentExtensions = data.extensionsForContractType[_contractType].values();
        uint256 len = currentExtensions.length;
        for (uint256 i = 0; i < len; i += 1) {
            data.extensionsForContractType[_contractType].remove(currentExtensions[i]);
        }

        len = _extensionNames.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                data.extensionNames.contains(_extensionNames[i]),
                "ExtensionRegistryState: extension does not exist."
            );
            data.extensionsForContractType[_contractType].add(_extensionNames[i]);
        }
    }

    function _registerContract(string memory _contractType, address _contract) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        require(data.allContractTypes.contains(_contractType), "ExtensionRegistryState: contract type does not exist.");
        require(
            data.defaultExtensionsForContract[_contract].length == 0,
            "ExtensionRegistryState: contract already registered."
        );

        string[] memory extensionNames = data.extensionsForContractType[_contractType].values();
        uint256 len = extensionNames.length;

        for (uint256 i = 0; i < len; i += 1) {
            string memory extensionName = extensionNames[i];
            uint256 extensionId = data.nextIdForExtension[extensionName] - 1;
            data.defaultExtensionsForContract[_contract].push(ExtensionID(extensionName, extensionId));
        }
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

        bytes32 extensionIdHash = keccak256(abi.encodePacked(name, nextId));

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
            data.extensionForFunction[_extension.functions[i].functionSelector][extensionIdHash] = _extension.metadata;
        }
    }

    /// @dev Updates / overrides an existing extension in the contract.
    function _updateExtension(Extension memory _extension) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        string memory name = _extension.metadata.name;
        require(data.extensionNames.contains(name), "ExtensionRegistryState: extension does not exist.");

        uint256 nextId = data.nextIdForExtension[name];
        data.nextIdForExtension[name] += 1;

        bytes32 extensionIdHash = keccak256(abi.encodePacked(name, nextId));

        address oldImplementation = data.extensions[name][nextId - 1].metadata.implementation;
        require(
            _extension.metadata.implementation != address(0) && _extension.metadata.implementation != oldImplementation,
            "ExtensionRegistryState: invalid implementation for update."
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
            data.extensionForFunction[_extension.functions[i].functionSelector][extensionIdHash] = _extension.metadata;
        }
    }

    /// @dev Removes an existing extension from the contract.
    function _removeExtension(string memory _extensionName) internal {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        require(data.extensionNames.remove(_extensionName), "ExtensionRegistryState: extension does not exist.");
    }
}
