// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../extension/interface/INFTMetadata.sol";

library NFTMetadataStorage {
    bytes32 public constant NFT_METADATA_STORAGE_POSITION = keccak256("metadata.override.storage");

    struct Data {
        /// @dev Mapping from NFT tokenID => NFT metadata URI.
        mapping(uint256 => string) tokenURI;
    }

    function nftMetadataStorage() internal pure returns (Data storage nftMetadataData) {
        bytes32 position = NFT_METADATA_STORAGE_POSITION;
        assembly {
            nftMetadataData.slot := position
        }
    }
}

abstract contract NFTMetadata is INFTMetadata {
    /// @notice Returns the metadata URI for a given NFT.
    function _getTokenURI(uint256 _tokenId) public view virtual returns (string memory) {
        NFTMetadataStorage.Data storage data = NFTMetadataStorage.nftMetadataStorage();
        return data.tokenURI[_tokenId];
    }

    /// @notice Sets the metadata URI for a given NFT.
    function setTokenURI(uint256 _tokenId, string memory _uri) public virtual {
        require(_canSetMetadata(), "Not authorized to set metadata");
        NFTMetadataStorage.Data storage data = NFTMetadataStorage.nftMetadataStorage();
        string memory prev = data.tokenURI[_tokenId];
        data.tokenURI[_tokenId] = _uri;
        emit TokenURIUpdated(_tokenId, prev, _uri);
    }

    /// @dev Returns whether metadata can be set in the given execution context.
    function _canSetMetadata() internal view virtual returns (bool);
}
