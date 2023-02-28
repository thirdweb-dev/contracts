// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/ILazyMintWithTier.sol";
import "./BatchMintMetadata.sol";

library LazyMintWithTierStorage {
    bytes32 public constant LAZY_MINT_WITH_TIER_STORAGE_POSITION = keccak256("lazy.mint.with.tier.storage");

    struct Data {
        /// @notice The tokenId assigned to the next new NFT to be lazy minted.
        uint256 nextTokenIdToLazyMint;
        /// @notice Mapping from a tier -> the token IDs grouped under that tier.
        mapping(string => ILazyMintWithTier.TokenRange[]) tokensInTier;
        /// @notice A list of tiers used in this contract.
        string[] tiers;
    }

    function lazyMintWithTierStorage() internal pure returns (Data storage lazyMintWithTierData) {
        bytes32 position = LAZY_MINT_WITH_TIER_STORAGE_POSITION;
        assembly {
            lazyMintWithTierData.slot := position
        }
    }
}

/**
 *  The `LazyMint` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract, without actually
 *  minting a non-zero balance of NFTs of those tokenIds.
 */

abstract contract LazyMintWithTier is ILazyMintWithTier, BatchMintMetadata {
    function nextTokenIdToLazyMint() internal view returns (uint256) {
        LazyMintWithTierStorage.Data storage data = LazyMintWithTierStorage.lazyMintWithTierStorage();
        return data.nextTokenIdToLazyMint;
    }

    function tokensInTier(string memory _tier) internal view returns (TokenRange[] memory) {
        LazyMintWithTierStorage.Data storage data = LazyMintWithTierStorage.lazyMintWithTierStorage();
        return data.tokensInTier[_tier];
    }

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

        uint256 startId = nextTokenIdToLazyMint();

        LazyMintWithTierStorage.Data storage data = LazyMintWithTierStorage.lazyMintWithTierStorage();

        (data.nextTokenIdToLazyMint, batchId) = _batchMintMetadata(startId, _amount, _baseURIForTokens);

        // Handle tier info.
        if (!(data.tokensInTier[_tier].length > 0)) {
            data.tiers.push(_tier);
        }
        data.tokensInTier[_tier].push(TokenRange(startId, batchId));

        emit TokensLazyMinted(_tier, startId, startId + _amount - 1, _baseURIForTokens, _data);

        return batchId;
    }

    /// @notice Returns all metadata lazy minted for the given tier.
    function _getMetadataInTier(string memory _tier)
        private
        view
        returns (TokenRange[] memory tokens, string[] memory baseURIs)
    {
        LazyMintWithTierStorage.Data storage data = LazyMintWithTierStorage.lazyMintWithTierStorage();

        tokens = data.tokensInTier[_tier];

        uint256 len = tokens.length;
        baseURIs = new string[](len);

        for (uint256 i = 0; i < len; i += 1) {
            baseURIs[i] = _getBaseURI(tokens[i].startIdInclusive);
        }
    }

    /// @notice Returns all metadata for all tiers created on the contract.
    function getMetadataForAllTiers() external view returns (TierMetadata[] memory metadataForAllTiers) {
        LazyMintWithTierStorage.Data storage data = LazyMintWithTierStorage.lazyMintWithTierStorage();

        string[] memory allTiers = data.tiers;
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
        LazyMintWithTierStorage.Data storage data = LazyMintWithTierStorage.lazyMintWithTierStorage();
        return data.tokensInTier[_tier].length == 0;
    }

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual returns (bool);
}
