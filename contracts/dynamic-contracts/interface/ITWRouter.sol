// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IRouter.sol";
import "lib/dynamic-contracts/src/interface/IExtension.sol";

interface ITWRouter is IRouter, IExtension {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(string memory extensionName) external;

    /// @dev Updates an existing extension in the router, or overrides a default extension.
    function updateExtension(string memory extensionName) external;

    /// @dev Removes an existing extension from the router.
    function removeExtension(string memory extensionName) external;

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all extensions stored.
    function getAllExtensions() external view returns (Extension[] memory);

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) external view returns (Extension memory);

    /// @dev Returns the extension metadata for a given function.
    function getExtensionForFunction(bytes4 functionSelector) external view returns (ExtensionMetadata memory);
}
