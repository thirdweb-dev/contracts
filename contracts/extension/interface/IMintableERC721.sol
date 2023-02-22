// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IMintableERC721 {
    /// @dev Emitted when tokens are minted via `mintTo`
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);

    /**
     *  @notice Lets an account mint an NFT.
     *
     *  @param to The address to mint the NFT to.
     *  @param uri The URI to assign to the NFT.
     *
     *  @return tokenId of the NFT minted.
     */
    function mintTo(address to, string calldata uri) external returns (uint256);
}
