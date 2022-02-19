// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

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
     *  @notice The set of all claim conditionsl, at any given moment.
     *
     *  @param totalConditionCount        Acts as the uid for each claim condition. Incremented
     *                                    by one every time a claim condition is created.
     *
     *  @param timstampLimitIndex         The index of the claim condition last claim timestamp.
     *
     *  @param claimConditionAtIndex      The claim conditions at a given uid. Claim conditions
     *                                    are ordered in an ascending order by their `startTimestamp`.

     *  @param merkleClaimProofAtIndex    claim condition index => bitmap of merkle proof claimed.

     *  @param timestampOfLastClaim       Account => uid for a claim condition => the last timestamp at
     *                                    which the account claimed tokens.
     */
    struct ClaimConditions {
        uint256 totalConditionCount;
        uint256 timstampLimitIndex;
        mapping(uint256 => ClaimCondition) claimConditionAtIndex;
        mapping(uint256 => BitMaps.BitMap) merkleClaimProofAtIndex;
        mapping(address => mapping(uint256 => uint256)) timestampOfLastClaim;
    }
}
