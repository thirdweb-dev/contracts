// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/ILazyMintWithTier.sol";
import "../extension/BatchMintMetadata.sol";

/**
 *  The `LazyMint` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract, without actually
 *  minting a non-zero balance of NFTs of those tokenIds.
 */

abstract contract LazyMintWithTier is ILazyMintWithTier, BatchMintMetadata {
    struct TokenRange {
        uint256 startIdInclusive;
        uint256 endIdNonInclusive;
    }

    struct TierMetadata {
        string tier;
        TokenRange[] ranges;
        string[] baseURIs;
    }

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    uint256 internal nextTokenIdToLazyMint;

    /// @notice Mapping from a tier -> the token IDs grouped under that tier.
    mapping(string => TokenRange[]) internal tokensInTier;

    /// @notice A list of tiers used in this contract.
    string[] private tiers;

    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The base URI for the 'n' number of NFTs being lazy minted, where the metadata for each
     *                           of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *  @param _data             Additional bytes data to be used at the discretion of the consumer of the contract.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        string calldata _tier,
        bytes calldata _data
    ) public virtual override returns (uint256 batchId) {
        if (!_canLazyMint()) {
            revert("Not authorized");
        }

        if (_amount == 0) {
            revert("0 amt");
        }

        uint256 startId = nextTokenIdToLazyMint;

        (nextTokenIdToLazyMint, batchId) = _batchMintMetadata(startId, _amount, _baseURIForTokens);

        // Handle tier info.
        if (!(tokensInTier[_tier].length > 0)) {
            tiers.push(_tier);
        }
        tokensInTier[_tier].push(TokenRange(startId, batchId));

        emit TokensLazyMinted(_tier, startId, startId + _amount - 1, _baseURIForTokens, _data);

        return batchId;
    }

    /// @notice Returns all metadata lazy minted for the given tier.
    function _getMetadataInTier(string memory _tier)
        private
        view
        returns (TokenRange[] memory tokens, string[] memory baseURIs)
    {
        tokens = tokensInTier[_tier];

        uint256 len = tokens.length;
        baseURIs = new string[](len);

        for (uint256 i = 0; i < len; i += 1) {
            baseURIs[i] = _getBaseURI(tokens[i].startIdInclusive);
        }
    }

    /// @notice Returns all metadata for all tiers created on the contract.
    function getMetadataForAllTiers() external view returns (TierMetadata[] memory metadataForAllTiers) {
        string[] memory allTiers = tiers;
        uint256 len = allTiers.length;

        metadataForAllTiers = new TierMetadata[](len);

        for (uint256 i = 0; i < len; i += 1) {
            (TokenRange[] memory tokens, string[] memory baseURIs) = _getMetadataInTier(allTiers[i]);
            metadataForAllTiers[i] = TierMetadata(allTiers[i], tokens, baseURIs);
        }
    }

    /**
     *  @notice Returns whether any metadata is lazy minted for the given tier.
     *
     *  @param _tier We check whether this given tier is empty.
     */
    function isTierEmpty(string memory _tier) internal view returns (bool) {
        return tokensInTier[_tier].length == 0;
    }

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual returns (bool);
}
