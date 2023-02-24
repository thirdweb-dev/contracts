// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./IExtension.sol";

interface IDefaultExtensionSet is IExtension {
    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns all extensions stored.
    function getAllExtensions() external view returns (Extension[] memory);

    /// @dev Returns all functions that belong to the given extension contract.
    function getAllFunctionsOfExtension(string memory extensionName) external view returns (ExtensionFunction[] memory);

    /// @dev Returns the extension metadata for a given function.
    function getExtensionForFunction(bytes4 functionSelector) external view returns (ExtensionMetadata memory);

    /// @dev Returns the extension's implementation smart contract address.
    function getExtensionImplementation(string memory extensionName) external view returns (address);

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) external view returns (Extension memory);
}
