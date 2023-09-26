// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/INFTMetadata.sol";

abstract contract NFTMetadata is INFTMetadata {
    bool public uriFrozen;

    mapping(uint256 => string) internal _tokenURI;

    /// @notice Returns the metadata URI for a given NFT.
    function _getTokenURI(uint256 _tokenId) internal view virtual returns (string memory) {
        return _tokenURI[_tokenId];
    }

    /// @notice Sets the metadata URI for a given NFT.
    function _setTokenURI(uint256 _tokenId, string memory _uri) internal virtual {
        require(bytes(_uri).length > 0, "NFTMetadata: empty metadata.");
        _tokenURI[_tokenId] = _uri;

        emit MetadataUpdate(_tokenId);
    }

    /// @notice Sets the metadata URI for a given NFT.
    function setTokenURI(uint256 _tokenId, string memory _uri) public virtual {
        require(_canSetMetadata(), "NFTMetadata: not authorized to set metadata.");
        require(!uriFrozen, "NFTMetadata: metadata is frozen.");
        _setTokenURI(_tokenId, _uri);
    }

    function freezeMetadata() public virtual {
        require(_canFreezeMetadata(), "NFTMetadata: not authorized to freeze metdata");
        uriFrozen = true;
        emit MetadataFrozen();
    }

    /// @dev Returns whether metadata can be set in the given execution context.
    function _canSetMetadata() internal view virtual returns (bool);

    function _canFreezeMetadata() internal view virtual returns (bool);
}
