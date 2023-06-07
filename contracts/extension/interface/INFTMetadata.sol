// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface INFTMetadata {
    /// @dev Emitted when the token URI is updated.
    event TokenURIUpdated(uint256 indexed tokenId, string prevURI, string newURI);

    /// @notice Sets the metadata URI for a given NFT.
    function setTokenURI(uint256 _tokenId, string memory _uri) external;
}
