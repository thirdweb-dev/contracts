// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IMap {
    event ExtensionRegistered(bytes4 indexed selector, address indexed extension);

    function setExtension(bytes4 _selector, address _extension) external;

    function getExtension(bytes4 _selector) external view returns (address);
}
