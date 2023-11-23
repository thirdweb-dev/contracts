// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.10;

/// @author thirdweb

interface ISharedMetadata {
    /// @notice Emitted when shared metadata is lazy minted.
    event SharedMetadataUpdated(string name, string description, string imageURI, string animationURI);

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

    /**
     *  @notice Set shared metadata for NFTs
     *  @param _metadata common metadata for all tokens
     */
    function setSharedMetadata(SharedMetadataInfo calldata _metadata) external;
}
