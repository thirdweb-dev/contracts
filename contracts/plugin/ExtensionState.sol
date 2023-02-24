// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "./interface/IExtension.sol";

// Extensions
import "../lib/TWStringSet.sol";

library ExtensionStateStorage {
    bytes32 public constant EXTENSION_STATE_STORAGE_POSITION = keccak256("extension.state.storage");

    struct Data {
        /// @dev Set of names of all extensions stored.
        TWStringSet.Set extensionNames;
        /// @dev Mapping from extension name => `Extension` i.e. extension metadata and functions.
        mapping(string => IExtension.Extension) extensions;
        /// @dev Mapping from function selector => extension metadata of the extension the function belongs to.
        mapping(bytes4 => IExtension.ExtensionMetadata) extensionMetadata;
    }

    function extensionStateStorage() internal pure returns (Data storage extensionStateData) {
        bytes32 position = EXTENSION_STATE_STORAGE_POSITION;
        assembly {
            extensionStateData.slot := position
        }
    }
}

contract ExtensionState is IExtension {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Stores a new extension in the contract.
    function _addExtension(Extension memory _extension) internal {
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();

        string memory name = _extension.metadata.name;

        require(data.extensionNames.add(name), "ExtensionState: extension already exists.");
        data.extensions[name].metadata = _extension.metadata;

        require(
            _extension.metadata.implementation != address(0),
            "ExtensionState: adding extension without implementation."
        );

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _extension.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature))),
                "ExtensionState: fn selector and signature mismatch."
            );
            require(
                data.extensionMetadata[_extension.functions[i].functionSelector].implementation == address(0),
                "ExtensionState: extension already exists for function."
            );

            data.extensionMetadata[_extension.functions[i].functionSelector] = _extension.metadata;
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
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();

        string memory name = _extension.metadata.name;
        require(data.extensionNames.contains(name), "ExtensionState: extension does not exist.");

        address oldImplementation = data.extensions[name].metadata.implementation;
        require(_extension.metadata.implementation != oldImplementation, "ExtensionState: re-adding same extension.");

        data.extensions[name].metadata = _extension.metadata;

        ExtensionFunction[] memory oldFunctions = data.extensions[name].functions;
        uint256 oldFunctionsLen = oldFunctions.length;

        delete data.extensions[name].functions;

        for (uint256 i = 0; i < oldFunctionsLen; i += 1) {
            delete data.extensionMetadata[oldFunctions[i].functionSelector];
        }

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            require(
                _extension.functions[i].functionSelector ==
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature))),
                "ExtensionState: fn selector and signature mismatch."
            );

            data.extensionMetadata[_extension.functions[i].functionSelector] = _extension.metadata;
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
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();

        require(data.extensionNames.remove(_extensionName), "ExtensionState: extension does not exist.");

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
            delete data.extensionMetadata[extensionFunctions[i].functionSelector];
        }
    }
}
