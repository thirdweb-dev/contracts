// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract ThirdwebContract {
    /// @dev The publish metadata of the contract of which this contract is an instance.
    string private publishMetadataUri;

    /// @dev Returns the publish metadata for this contract.
    function getPublishMetadataUri() external view returns (string memory) {
        return publishMetadataUri;
    }

    /// @dev Initializes the publish metadata and at deploy time.
    function setPublisheMetadataUi(string memory uri) external {
        require(bytes(publishMetadataUri).length == 0, "Published metadata already initialized");
        publishMetadataUri = uri;
    }
}
