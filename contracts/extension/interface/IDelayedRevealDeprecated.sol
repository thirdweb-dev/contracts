// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

// [ DEPRECATED CONTRACT: use `contracts/extension/interface/IDelayedReveal.sol` instead ]

/**
 *  Thirdweb's `DelayedReveal` is a contract extension for base NFT contracts. It lets you create batches of
 *  'delayed-reveal' NFTs. You can learn more about the usage of delayed reveal NFTs here - https://blog.thirdweb.com/delayed-reveal-nfts
 */

interface IDelayedRevealDeprecated {
    /// @dev Emitted when tokens are revealed.
    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    /// @dev Returns the encrypted base URI associated with the given identifier.
    function encryptedBaseURI(uint256 identifier) external view returns (bytes memory);

    /**
     *  @notice Reveals a batch of delayed reveal NFTs.
     *
     *  @param identifier The ID for the batch of delayed-reveal NFTs to reveal.
     *
     *  @param key        The key with which the base URI for the relevant batch of NFTs was encrypted.
     */
    function reveal(uint256 identifier, bytes calldata key) external returns (string memory revealedURI);

    /**
     *  @notice Performs XOR encryption/decryption.
     *
     *  @param data The data to encrypt. In the case of delayed-reveal NFTs, this is the "revealed" state
     *              base URI of the relevant batch of NFTs.
     *
     *  @param key  The key with which to encrypt data
     */
    function encryptDecrypt(bytes memory data, bytes calldata key) external pure returns (bytes memory result);
}
