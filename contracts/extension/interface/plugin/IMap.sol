// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IMap {
    struct ExtensionMap {
        bytes4 selector;
        address extension;
    }

    event ExtensionRegistered(bytes4 indexed selector, address indexed extension);

    function getExtensionForFunction(bytes4 _selector) external view returns (address);

    function getAllFunctionsOfExtension(address _extension) external view returns (bytes4[] memory registered);

    function getAllRegistered() external view returns (ExtensionMap[] memory registered);
}
