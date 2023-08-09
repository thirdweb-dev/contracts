// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.10;

/// @author thirdweb

import "../../lib/NFTMetadataRendererLib.sol";
import "../../extension/interface/ISharedMetadata.sol";
import "../../eip/interface/IERC4906.sol";

/**
 *  @title   Shared Metadata
 *  @notice  Store a of shared metadata for NFTs
 */
library SharedMetadataStorage {
    bytes32 public constant SHARED_METADATA_STORAGE_POSITION = keccak256("shared.metadata.storage");

    struct Data {
        /// @notice Token metadata information
        ISharedMetadata.SharedMetadataInfo sharedMetadata;
    }

    function sharedMetadataStorage() internal pure returns (Data storage sharedMetadataData) {
        bytes32 position = SHARED_METADATA_STORAGE_POSITION;
        assembly {
            sharedMetadataData.slot := position
        }
    }
}

abstract contract SharedMetadata is ISharedMetadata, IERC4906 {
    /// @notice Returns the shared metadata.
    function sharedMetadata() external view virtual returns (SharedMetadataInfo memory) {
        return SharedMetadataStorage.sharedMetadataStorage().sharedMetadata;
    }

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
        SharedMetadataStorage.sharedMetadataStorage().sharedMetadata = SharedMetadataInfo({
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
        SharedMetadataInfo memory info = SharedMetadataStorage.sharedMetadataStorage().sharedMetadata;

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
