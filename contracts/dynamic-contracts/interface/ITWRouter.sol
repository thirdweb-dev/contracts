// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IDefaultExtensionSet.sol";

interface ITWRouter is IDefaultExtensionSet {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(string memory extensionName) external;

    /// @dev Updates an existing extension in the router, or overrides a default extension.
    function updateExtension(string memory extensionName) external;

    /// @dev Removes an existing extension from the router.
    function removeExtension(string memory extensionName) external;
}
