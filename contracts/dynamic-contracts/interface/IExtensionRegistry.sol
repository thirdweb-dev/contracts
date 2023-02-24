// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IDefaultExtensionSet.sol";

interface IExtensionRegistry is IDefaultExtensionSet {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the registry.
    function addExtension(Extension memory extension) external;

    /// @dev Updates an existing extension in the registry.
    function updateExtension(Extension memory extension) external;

    /// @dev Remove an existing extension from the registry.
    function removeExtension(string memory extension) external;
}
