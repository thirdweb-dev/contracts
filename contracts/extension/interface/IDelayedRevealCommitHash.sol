// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `DelayedRevealCommitHash` is a contract extension for base NFT contracts. It lets you create batches of
 *  'delayed-reveal' NFTs by (1) first publishing the provenance hash of the NFTs' metadata URI, and later (2) publishing
 *  the metadata URI of the NFTs which is checked against the provenance hash.
 */

interface IDelayedRevealCommitHash {
    /// @dev Emitted when tokens are revealed.
    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    /**
     *  @notice Returns the provenance hash of NFTs grouped by the given identifier.
     *
     *  @param identifier The identifier by which the relevant NFTs are grouped.
     */
    function baseURICommitHash(uint256 identifier) external view returns (bytes32);

    /**
     *  @notice Returns whether the given metadata URI is the true metadata URI associated with the provenance hash
     *          for NFTs grouped by the given identifier.
     *
     *  @param identifier      The identifier by which the relevant NFTs are grouped.
     *  @param salt            The salt used to arrive at the relevant provenance hash.
     *  @param baseURIToReveal The metadata URI of the relevant NFTs checked against the relevant provenance hash.
     */
    function isValidBaseURI(uint256 identifier, bytes32 salt, string calldata baseURIToReveal) external view returns (bool);

    /**
     *  @notice Reveals a batch of delayed reveal NFTs grouped by the given identifier.
     *
     *  @param identifier      The identifier by which the relevant NFTs are grouped.
     *  @param salt            The salt used to arrive at the relevant provenance hash.
     *  @param baseURIToReveal The metadata URI of the relevant NFTs checked against the relevant provenance hash.
     */
    function reveal(uint256 identifier, bytes32 salt, string calldata baseURIToReveal) external returns (string memory revealedURI);
}
