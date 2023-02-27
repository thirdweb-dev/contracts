// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/ITWRouter.sol";
import "./interface/IExtensionRegistry.sol";

// Extensions & libraries
import "../extension/Multicall.sol";

// Extension pattern imports
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";
import "lib/dynamic-contracts/src/core/Router.sol";
import "lib/dynamic-contracts/src/presets/utils/DefaultExtensionSet.sol";
import "lib/dynamic-contracts/src/presets/utils/ExtensionState.sol";

abstract contract TWRouter is ITWRouter, Multicall, ExtensionState, Router {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The DefaultExtensionSet that stores default extensions of the router.
    address public immutable defaultExtensionSet;

    /// @notice The ExtensionRegistry that stores all latest, vetted extensions available to router.
    address public immutable extensionRegistry;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _extensionRegistry, string[] memory _extensionNames) {
        extensionRegistry = _extensionRegistry;

        DefaultExtensionSet map = new DefaultExtensionSet();
        defaultExtensionSet = address(map);

        uint256 len = _extensionNames.length;

        for (uint256 i = 0; i < len; i += 1) {
            Extension memory extension = IExtensionRegistry(_extensionRegistry).getExtension(_extensionNames[i]);
            map.setExtension(extension);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(string memory _extensionName) external {
        require(_canSetExtension(), "TWRouter: caller not authorized");

        Extension memory extension = IExtensionRegistry(extensionRegistry).getExtension(_extensionName);

        _addExtension(extension);
    }

    /// @dev Updates an existing extension in the router, or overrides a default extension.
    function updateExtension(string memory _extensionName) external {
        require(_canSetExtension(), "TWRouter: caller not authorized");

        Extension memory extension = IExtensionRegistry(extensionRegistry).getExtension(_extensionName);

        _updateExtension(extension);
    }

    /// @dev Removes an existing extension from the router.
    function removeExtension(string memory _extensionName) external {
        require(_canSetExtension(), "TWRouter: caller not authorized");

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
        Extension[] memory mapExtensions = IDefaultExtensionSet(defaultExtensionSet).getAllExtensions();
        uint256 mapExtensionsLen = mapExtensions.length;

        ExtensionStateStorage.Data storage data = ExtensionStateStorage.extensionStateStorage();
        string[] memory names = data.extensionNames.values();
        uint256 namesLen = names.length;

        uint256 overrides = 0;
        for (uint256 i = 0; i < mapExtensionsLen; i += 1) {
            if (data.extensionNames.contains(mapExtensions[i].metadata.name)) {
                overrides += 1;
            }
        }

        uint256 total = (namesLen + mapExtensionsLen) - overrides;

        allExtensions = new Extension[](total);
        uint256 idx = 0;

        for (uint256 i = 0; i < mapExtensionsLen; i += 1) {
            string memory name = mapExtensions[i].metadata.name;
            if (!data.extensionNames.contains(name)) {
                allExtensions[idx] = mapExtensions[i];
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

    /// @dev Returns the Extension metadata for a given function.
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
