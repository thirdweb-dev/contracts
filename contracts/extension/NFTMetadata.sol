// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/INFTMetadata.sol";

abstract contract NFTMetadata is INFTMetadata {
    mapping(uint256 => string) private _tokenURI;

    /// @notice Returns the metadata URI for a given NFT.
    function _getTokenURI(uint256 _tokenId) internal view virtual returns (string memory) {
        return _tokenURI[_tokenId];
    }

    /// @notice SEts the metadata URI for a given NFT.
    function _setTokenURI(uint256 _tokenId, string memory _uri) internal virtual {
        require(bytes(_uri).length > 0, "NFTMetadata: empty metadata.");
        _tokenURI[_tokenId] = _uri;

        emit MetadataUpdate(_tokenId);
    }

    /// @notice Sets the metadata URI for a given NFT.
    function setTokenURI(uint256 _tokenId, string memory _uri) public virtual {
        require(_canSetMetadata(), "Not authorized to set metadata");
        _setTokenURI(_tokenId, _uri);
    }

    /// @dev Returns whether metadata can be set in the given execution context.
    function _canSetMetadata() internal view virtual returns (bool);
}
