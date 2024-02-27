// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/INFTMetadata.sol";

abstract contract NFTMetadata is INFTMetadata {
    /// @dev The sender is not authorized to perform the action
    error NFTMetadataUnauthorized();

    /// @dev Invalid token metadata url
    error NFTMetadataInvalidUrl();

    /// @dev the nft metadata is frozen
    error NFTMetadataFrozen(uint256 tokenId);

    bool public uriFrozen;

    mapping(uint256 => string) internal _tokenURI;

    /// @notice Returns the metadata URI for a given NFT.
    function _getTokenURI(uint256 _tokenId) internal view virtual returns (string memory) {
        return _tokenURI[_tokenId];
    }

    /// @notice Sets the metadata URI for a given NFT.
    function _setTokenURI(uint256 _tokenId, string memory _uri) internal virtual {
        if (bytes(_uri).length == 0) {
            revert NFTMetadataInvalidUrl();
        }
        _tokenURI[_tokenId] = _uri;

        emit MetadataUpdate(_tokenId);
    }

    /// @notice Sets the metadata URI for a given NFT.
    function setTokenURI(uint256 _tokenId, string memory _uri) public virtual {
        if (!_canSetMetadata()) {
            revert NFTMetadataUnauthorized();
        }
        if (uriFrozen) {
            revert NFTMetadataFrozen(_tokenId);
        }
        _setTokenURI(_tokenId, _uri);
    }

    function freezeMetadata() public virtual {
        if (!_canFreezeMetadata()) {
            revert NFTMetadataUnauthorized();
        }
        uriFrozen = true;
        emit MetadataFrozen();
    }

    /// @dev Returns whether metadata can be set in the given execution context.
    function _canSetMetadata() internal view virtual returns (bool);

    function _canFreezeMetadata() internal view virtual returns (bool);
}
