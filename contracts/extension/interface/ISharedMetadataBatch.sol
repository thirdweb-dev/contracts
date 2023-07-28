// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.10;

/// @author thirdweb

interface ISharedMetadataBatch {
    /// @notice Emitted when shared metadata is lazy minted.
    event SharedMetadataUpdated(
        bytes32 indexed id,
        string name,
        string description,
        string imageURI,
        string animationURI
    );

    /// @notice Emitted when shared metadata is deleted.
    event SharedMetadataDeleted(bytes32 indexed id);

    /**
     *  @notice Structure for metadata shared across all tokens
     *
     *  @param name Shared name of NFT in metadata
     *  @param description Shared description of NFT in metadata
     *  @param imageURI Shared URI of image to render for NFTs
     *  @param animationURI Shared URI of animation to render for NFTs
     */
    struct SharedMetadataInfo {
        string name;
        string description;
        string imageURI;
        string animationURI;
    }

    struct SharedMetadataWithId {
        bytes32 id;
        SharedMetadataInfo metadata;
    }

    /**
     *  @notice Set shared metadata for NFTs
     *  @param metadata common metadata for all tokens
     *  @param id UID for the metadata
     */
    function setSharedMetadata(SharedMetadataInfo calldata metadata, bytes32 id) external;

    /**
     *  @notice Delete shared metadata for NFTs
     *  @param id UID for the metadata
     */
    function deleteSharedMetadata(bytes32 id) external;

    /**
     *  @notice Get all shared metadata
     *  @return metadata array of all shared metadata
     */
    function getAllSharedMetadata() external view returns (SharedMetadataWithId[] memory metadata);
}
