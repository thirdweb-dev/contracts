// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.10;

/// @author thirdweb

import "../lib/NFTMetadataRendererLib.sol";
import "./interface/ISharedMetadata.sol";
import "../eip/interface/IERC4906.sol";

abstract contract SharedMetadata is ISharedMetadata, IERC4906 {
    /// @notice Token metadata information
    SharedMetadataInfo public sharedMetadata;

    /// @notice Set shared metadata for NFTs
    function setSharedMetadata(SharedMetadataInfo calldata _metadata) external virtual {
        if (!_canSetSharedMetadata()) {
            revert("Not authorized");
        }
        _setSharedMetadata(_metadata);
    }

    /**
     *  @dev Sets shared metadata for NFTs.
     *  @param _metadata common metadata for all tokens
     */
    function _setSharedMetadata(SharedMetadataInfo calldata _metadata) internal {
        sharedMetadata = SharedMetadataInfo({
            name: _metadata.name,
            description: _metadata.description,
            imageURI: _metadata.imageURI,
            animationURI: _metadata.animationURI
        });

        emit BatchMetadataUpdate(0, type(uint256).max);

        emit SharedMetadataUpdated({
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
        SharedMetadataInfo memory info = sharedMetadata;

        return
            NFTMetadataRenderer.createMetadataEdition({
                name: info.name,
                description: info.description,
                imageURI: info.imageURI,
                animationURI: info.animationURI,
                tokenOfEdition: tokenId
            });
    }

    /// @dev Returns whether shared metadata can be set in the given execution context.
    function _canSetSharedMetadata() internal view virtual returns (bool);
}
