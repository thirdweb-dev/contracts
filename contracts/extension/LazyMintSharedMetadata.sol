// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.10;

/// @author thirdweb

import "../lib/NFTMetadataRendererLib.sol";
import "./interface/ILazyMintSharedMetadata.sol";

abstract contract LazyMintSharedMetadata is ILazyMintSharedMetadata {
    /// @notice Token metadata information
    SharedMetadata public sharedMetadata;

    /// @notice Lazy mint shared metadata
    function lazyMintSharedMetadata(SharedMetadata calldata _metadata) external virtual {
        if (!_canLazyMint()) {
            revert("Not authorized");
        }
        _setSharedMetadata(_metadata);
    }

    /**
     *  @dev Default initializer for edition data from a specific contract
     *  @param _metadata common metadata for all tokens
     */
    function _setSharedMetadata(SharedMetadata calldata _metadata) internal {
        sharedMetadata = SharedMetadata({
            name: _metadata.name,
            description: _metadata.description,
            imageURI: _metadata.imageURI,
            animationURI: _metadata.animationURI
        });

        emit SharedMetadataLazyMinted({
            name: _metadata.name,
            description: _metadata.description,
            imageURI: _metadata.imageURI,
            animationURI: _metadata.animationURI
        });
    }

    /**
     *  @dev Token URI information getter
     *  @param tokenId Token ID to get URI for
     */
    function _getURIFromSharedMetadata(uint256 tokenId) internal view returns (string memory) {
        SharedMetadata memory info = sharedMetadata;

        return
            NFTMetadataRenderer.createMetadataEdition({
                name: info.name,
                description: info.description,
                imageURI: info.imageURI,
                animationURI: info.animationURI,
                tokenOfEdition: tokenId
            });
    }

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual returns (bool);
}
