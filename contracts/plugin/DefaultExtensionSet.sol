// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IDefaultExtensionSet.sol";

// Extensions
import "./ExtensionState.sol";
import "../lib/TWStringSet.sol";

contract DefaultExtensionSet is IDefaultExtensionSet, ExtensionState {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The deployer of DefaultExtensionSet.
    address private deployer;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        deployer = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Stores a extension in the DefaultExtensionSet.
    function setExtension(Extension memory _extension) external {
        require(msg.sender == deployer, "DefaultExtensionSet: unauthorized caller.");
        _addExtension(_extension);
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
        require(data.extensionNames.contains(_extensionName), "DefaultExtensionSet: extension does not exist.");
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
        require(metadata.implementation != address(0), "DefaultExtensionSet: no extension for function.");
        return metadata;
    }
}
