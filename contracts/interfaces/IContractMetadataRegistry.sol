// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContractMetadataRegistry {
    /// @dev Emitted when a contract metadata is registered
    event MetadataRegistered(address indexed contractAddress, string metadataUri);

    /// @dev Records `metadataUri` as metadata for the contract at `contractAddress`.
    function registerMetadata(address contractAddress, string memory metadataUri) external;
}
