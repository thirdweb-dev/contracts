// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IClaimCondition.sol";

interface IDropSinglePhase is IClaimCondition {
    struct AllowlistProof {
        bytes32[] proof;
        uint256 maxQuantityInAllowlist;
    }

    event TokensClaimed(
        ClaimCondition condition,
        address indexed claimer,
        address indexed receiver,
        uint256 quantityClaimed,
        uint256 indexed aux
    );

    event ClaimConditionUpdated(ClaimCondition condition, bool resetEligibility);

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param allowlistProof                 The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param data                           Arbitrary bytes data that can be leveraged in the implementation of this interface.
     */
    function claim(
        address receiver,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        AllowlistProof calldata allowlistProof,
        bytes memory data
    ) external payable;

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param phase                    Claim condition to set.
     *
     *  @param resetClaimEligibility    Whether to reset `limitLastClaimTimestamp` and `limitMerkleProofClaim` values when setting new
     *                                  claim conditions.
     *
     *  @param data                     Arbitrary bytes data that can be leveraged in the implementation of this interface.
     */
    function setClaimConditions(
        ClaimCondition calldata phase,
        bool resetClaimEligibility,
        bytes memory data
    ) external;
}
