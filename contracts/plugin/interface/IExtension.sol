// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

interface IExtension {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice A extension's metadata.
     *
     *  @param name             The unique name of the extension.
     *  @param metadataURI      The URI where the metadata for the extension lives.
     *  @param implementation   The implementation smart contract address of the extension.
     */
    struct ExtensionMetadata {
        string name;
        string metadataURI;
        address implementation;
    }

    /**
     *  @notice An interface to describe a extension's function.
     *
     *  @param functionSelector    The 4 byte selector of the function.
     *  @param functionSignature   Function signature as a string. E.g. "transfer(address,address,uint256)"
     */
    struct ExtensionFunction {
        bytes4 functionSelector;
        string functionSignature;
    }

    /**
     *  @notice An interface to describe an extension.
     *
     *  @param metadata     The extension's metadata; it's name, metadata URI and implementation contract address.
     *  @param functions    The functions that belong to the extension.
     */
    struct Extension {
        ExtensionMetadata metadata;
        ExtensionFunction[] functions;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a extension is added; emitted for each function of the extension.
    event ExtensionAdded(address indexed extensionAddress, bytes4 indexed functionSelector, string functionSignature);

    /// @dev Emitted when extension is updated; emitted for each function of the extension.
    event ExtensionUpdated(
        address indexed oldExtensionAddress,
        address indexed newExtensionAddress,
        bytes4 indexed functionSelector,
        string functionSignature
    );

    /// @dev Emitted when a extension is removed; emitted for each function of the extension.
    event ExtensionRemoved(address indexed extensionAddress, bytes4 indexed functionSelector, string functionSignature);
}
