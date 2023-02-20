// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { LazyMintWithTier } from "../../extension/LazyMintWithTier.sol";

library TieredDropStorage {
    bytes32 public constant TIERED_DROP_STORAGE_POSITION = keccak256("tiered.drop.storage");

    struct Data {
        /**
         *  @dev Conceptually, tokens are minted on this contract one-batch-of-a-tier at a time. Each batch is comprised of
         *       a given range of tokenIds [startId, endId).
         *
         *       This array stores each such endId, in chronological order of minting.
         */
        uint256 lengthEndIdsAtMint;
        mapping(uint256 => uint256) endIdsAtMint;
        /**
         *  @dev Conceptually, tokens are minted on this contract one-batch-of-a-tier at a time. Each batch is comprised of
         *       a given range of tokenIds [startId, endId).
         *
         *       This is a mapping from such an `endId` -> the tier that tokenIds [startId, endId) belong to.
         *       Together with `endIdsAtMint`, this mapping is used to return the tokenIds that belong to a given tier.
         */
        mapping(uint256 => string) tierAtEndId;
        /**
         *  @dev This contract lets an admin lazy mint batches of metadata at once, for a given tier. E.g. an admin may lazy mint
         *       the metadata of 5000 tokens that will actually be minted in the future.
         *
         *       Lazy minting of NFT metafata happens from a start metadata ID (inclusive) to an end metadata ID (non-inclusive),
         *       where the lazy minted metadata lives at `providedBaseURI/${metadataId}` for each unit metadata.
         *
         *       At the time of actual minting, the minter specifies the tier of NFTs they're minting. So, the order in which lazy minted
         *       metadata for a tier is assigned integer IDs may differ from the actual tokenIds minted for a tier.
         *
         *       This is a mapping from an actually minted end tokenId -> the range of lazy minted metadata that now belongs
         *       to NFTs of [start tokenId, end tokenid).
         */
        mapping(uint256 => LazyMintWithTier.TokenRange) proxyTokenRange;
        /// @dev Mapping from tier -> the metadata ID up till which metadata IDs have been mapped to minted NFTs' tokenIds.
        mapping(string => uint256) nextMetadataIdToMapFromTier;
        /// @dev Mapping from tier -> how many units of lazy minted metadata have not yet been mapped to minted NFTs' tokenIds.
        mapping(string => uint256) totalRemainingInTier;
        /// @dev Mapping from batchId => tokenId offset for that batchId.
        mapping(uint256 => bytes32) tokenIdOffset;
        /// @dev Mapping from hash(tier, "minted") -> total minted in tier.
        mapping(bytes32 => uint256) totalsForTier;
    }

    function tieredDropStorage() internal pure returns (Data storage tieredDropData) {
        bytes32 position = TIERED_DROP_STORAGE_POSITION;
        assembly {
            tieredDropData.slot := position
        }
    }
}
