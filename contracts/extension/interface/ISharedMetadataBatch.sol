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
     *  @return id UID for the metadata
     */
    function createSharedMetadata(SharedMetadataInfo calldata metadata) external returns (bytes32 id);

    /**
     *  @notice Get all shared metadata
     *  @return metadata array of all shared metadata
     */
    function getAllSharedMetadata() external view returns (SharedMetadataWithId[] memory metadata);
}
