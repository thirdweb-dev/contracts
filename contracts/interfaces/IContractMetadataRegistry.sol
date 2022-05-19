// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IContractMetadataRegistry {
    /// @dev Emitted when a contract metadata is registered
    event MetadataRegistered(address indexed contractAddress, string metadataUri);

    function registerMetadata(address contractAddress, string memory metadataUri) external;
}
