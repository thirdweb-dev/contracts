// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "./interface/IBaseRouter.sol";

// Core
import "./Router.sol";

// Utils
import "../lib/TWStringSet.sol";
import "./DefaultExtensionSet.sol";
import "./ExtensionState.sol";

abstract contract BaseRouter is IBaseRouter, Router, ExtensionState {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The DefaultExtensionSet that stores default extensions of the router.
    address public immutable defaultExtensionSet;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(Extension[] memory _extensions) {
        DefaultExtensionSet map = new DefaultExtensionSet();
        defaultExtensionSet = address(map);

        uint256 len = _extensions.length;

        for (uint256 i = 0; i < len; i += 1) {
            map.setExtension(_extensions[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(Extension memory _extension) external {
        require(_canSetExtension(), "BaseRouter: caller not authorized.");

        _addExtension(_extension);
    }

    /// @dev Updates an existing extension in the router, or overrides a default extension.
    function updateExtension(Extension memory _extension) external {
        require(_canSetExtension(), "BaseRouter: caller not authorized.");

        _updateExtension(_extension);
    }

    /// @dev Removes an existing extension from the router.
    function removeExtension(string memory _extensionName) external {
        require(_canSetExtension(), "BaseRouter: caller not authorized.");

        _removeExtension(_extensionName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions stored. Override default lugins stored in router are
     *          given precedence over default extensions in DefaultExtensionSet.
     */
    function getAllExtensions() external view returns (Extension[] memory allExtensions) {
        Extension[] memory defaultExtensions = IDefaultExtensionSet(defaultExtensionSet).getAllExtensions();
        uint256 defaultExtensionsLen = defaultExtensions.length;

        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();
        string[] memory names = data.extensionNames.values();
        uint256 namesLen = names.length;

        uint256 overrides = 0;
        for (uint256 i = 0; i < defaultExtensionsLen; i += 1) {
            if (data.extensionNames.contains(defaultExtensions[i].metadata.name)) {
                overrides += 1;
            }
        }

        uint256 total = (namesLen + defaultExtensionsLen) - overrides;

        allExtensions = new Extension[](total);
        uint256 idx = 0;

        for (uint256 i = 0; i < defaultExtensionsLen; i += 1) {
            string memory name = defaultExtensions[i].metadata.name;
            if (!data.extensionNames.contains(name)) {
                allExtensions[idx] = defaultExtensions[i];
                idx += 1;
            }
        }

        for (uint256 i = 0; i < namesLen; i += 1) {
            allExtensions[idx] = data.extensions[names[i]];
            idx += 1;
        }
    }

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory _extensionName) public view returns (Extension memory) {
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();
        bool isLocalExtension = data.extensionNames.contains(_extensionName);

        return
            isLocalExtension
                ? data.extensions[_extensionName]
                : IDefaultExtensionSet(defaultExtensionSet).getExtension(_extensionName);
    }

    /// @dev Returns the extension's implementation smart contract address.
    function getExtensionImplementation(string memory _extensionName) external view returns (address) {
        return getExtension(_extensionName).metadata.implementation;
    }

    /// @dev Returns all functions that belong to the given extension contract.
    function getAllFunctionsOfExtension(string memory _extensionName)
        external
        view
        returns (ExtensionFunction[] memory)
    {
        return getExtension(_extensionName).functions;
    }

    /// @dev Returns the extension metadata for a given function.
    function getExtensionForFunction(bytes4 _functionSelector) public view returns (ExtensionMetadata memory) {
        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();
        ExtensionMetadata memory metadata = data.extensionMetadata[_functionSelector];

        bool isLocalExtension = metadata.implementation != address(0);

        return
            isLocalExtension
                ? metadata
                : IDefaultExtensionSet(defaultExtensionSet).getExtensionForFunction(_functionSelector);
    }

    /// @dev Returns the extension implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector)
        public
        view
        override
        returns (address extensionAddress)
    {
        return getExtensionForFunction(_functionSelector).implementation;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension() internal view virtual returns (bool);
}
