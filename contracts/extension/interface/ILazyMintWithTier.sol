// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `LazyMintWithTier` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once, for a particular tier. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract,
 *  without actually minting a non-zero balance of NFTs of those tokenIds.
 */

interface ILazyMintWithTier {
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(
        string indexed tier,
        uint256 indexed startTokenId,
        uint256 endTokenId,
        string baseURI,
        bytes encryptedBaseURI
    );

    /**
     *  @notice Lazy mints a given amount of NFTs.
     *
     *  @param amount           The number of NFTs to lazy mint.
     *
     *  @param baseURIForTokens The base URI for the 'n' number of NFTs being lazy minted, where the metadata for each
     *                          of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *
     *  @param tier             The tier for which these tokens are being lazy mitned. Here, `tier` is a unique string label
     *                          that is used to group together different batches of lazy minted tokens under a common category.
     *
     *  @param extraData        Additional bytes data to be used at the discretion of the consumer of the contract.
     *
     *  @return batchId         A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(
        uint256 amount,
        string calldata baseURIForTokens,
        string calldata tier,
        bytes calldata extraData
    ) external returns (uint256 batchId);
}
