// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

interface IDropClaimCondition {
    /**
     *  @notice The restrictions that make up a claim condition.
     *
     *  @param startTimestamp                 The unix timestamp after which the claim condition applies.
     *                                        The same claim condition applies until the `startTimestamp`
     *                                        of the next claim condition.
     *
     *  @param maxClaimableSupply             The maximum number of tokens that can
     *                                        be claimed under the claim condition.
     *
     *  @param supplyClaimed                  At any given point, the number of tokens that have been claimed.
     *
     *  @param quantityLimitPerTransaction    The maximum number of tokens a single account can
     *                                        claim in a single transaction.
     *
     *  @param waitTimeInSecondsBetweenClaims The least number of seconds an account must wait
     *                                        after claiming tokens, to be able to claim again.
     *
     *  @param merkleRoot                     Only accounts whitelisted by `merkleRoot` can claim tokens
     *                                        under the claim condition.
     *
     *  @param pricePerToken                  The price per token that can be claimed.
     *
     *  @param currency                       The currency in which `pricePerToken` must be paid.
     */
    struct ClaimCondition {
        uint256 startTimestamp;
        uint256 maxClaimableSupply;
        uint256 supplyClaimed;
        uint256 quantityLimitPerTransaction;
        uint256 waitTimeInSecondsBetweenClaims;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        address currency;
    }

    /**
     *  @notice The set of all claim conditions, at any given moment.
     *  Claim Phase ID = [currentStartId, currentStartId + length - 1];
     *
     *  @param currentStartId Acts as the uid for each claim condition. Incremented
     *                                    by one every time a claim condition is created.
     *
     *  @param count The total number of phases / claim condition in the list of claim conditions.
     *
     *  @param phases The claim conditions at a given uid. Claim conditions
     *                                    are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param limitLastClaimTimestamp Account => uid for a claim condition => the last timestamp at
     *                                    which the account claimed tokens.
     *
     *  @param limitMerkleProofClaim claim condition index => bitmap of merkle proof claimed.
     */
    struct ClaimConditionList {
        // the current index of Claim Phase ID
        uint256 currentStartId;
        // the total number of phases.
        uint256 count;
        // Claim Phase ID => Claim Phase
        mapping(uint256 => ClaimCondition) phases;
        // Claim Phase ID => Address => last claim timestamp. (per claim phases limits)
        mapping(uint256 => mapping(address => uint256)) limitLastClaimTimestamp;
        // Claim Phase ID => BitMaps merkle proof has claimed. (per claim phases limits)
        mapping(uint256 => BitMapsUpgradeable.BitMap) limitMerkleProofClaim;
    }
}
