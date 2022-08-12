// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IClaimCondition.sol";

interface IDropSinglePhase1155 is IClaimCondition {
    struct AllowlistProof {
        bytes32[] proof;
        uint256 maxQuantityInAllowlist;
    }

    /// @dev Emitted when tokens are claimed via `claim`.
    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 quantityClaimed
    );

    /// @dev Emitted when the contract's claim conditions are updated.
    event ClaimConditionUpdated(uint256 indexed tokenId, ClaimCondition condition, bool resetEligibility);

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param tokenId                        The tokenId of the NFT to claim.
     *  @param receiver                       The receiver of the NFT to claim.
     *  @param quantity                       The quantity of the NFT to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param allowlistProof                 The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param data                           Arbitrary bytes data that can be leveraged in the implementation of this interface.
     */
    function claim(
        address receiver,
        uint256 tokenId,
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
     *  @param tokenId                  The tokenId for which to set the relevant claim condition.
     */
    function setClaimConditions(
        uint256 tokenId,
        ClaimCondition calldata phase,
        bool resetClaimEligibility
    ) external;
}
