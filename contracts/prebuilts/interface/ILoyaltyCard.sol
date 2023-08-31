// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../extension/interface/INFTMetadata.sol";
import "../../extension/interface/ISignatureMintERC721.sol";
import "../../eip/interface/IERC721.sol";

interface ILoyaltyCard {
    /// @dev Emitted when an account with MINTER_ROLE mints an NFT.
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);

    /**
     *  @notice Lets an account with MINTER_ROLE mint an NFT.
     *
     *  @param to The address to mint the NFT to.
     *  @param uri The URI to assign to the NFT.
     *
     *  @return tokenId of the NFT minted.
     */
    function mintTo(address to, string calldata uri) external returns (uint256);

    /// @notice Let's a loyalty card owner or approved operator cancel the loyalty card.
    function cancel(uint256 tokenId) external;

    /// @notice Let's an approved party cancel the loyalty card (no approval needed).
    function revoke(uint256 tokenId) external;
}
