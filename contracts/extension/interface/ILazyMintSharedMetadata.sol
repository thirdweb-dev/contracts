// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.10;

/// @author thirdweb

interface ILazyMintSharedMetadata {
    /// @notice Emitted when shared metadata is lazy minted.
    event SharedMetadataLazyMinted(string name, string description, string imageURI, string animationURI);

    /**
     *  @notice Structure for metadata shared across all tokens
     *
     *  @param name Shared name of NFT in metadata
     *  @param description Shared description of NFT in metadata
     *  @param imageURI Shared URI of image to render for NFTs
     *  @param animationURI Shared URI of animation to render for NFTs
     */
    struct SharedMetadata {
        string name;
        string description;
        string imageURI;
        string animationURI;
    }

    /**
     *  @notice Lazy mint shared metadata
     *  @param _metadata common metadata for all tokens
     */
    function lazyMintSharedMetadata(SharedMetadata calldata _metadata) external;
}
