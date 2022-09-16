// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IClaimConditionMultiPhase.sol";

interface IDrop1155 is IClaimConditionMultiPhase {
    struct AllowlistProof {
        bytes32[] proof;
        uint256 quantityLimitPerWallet;
        uint256 pricePerToken;
        address currency;
    }

    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 tokenId,
        uint256 quantityClaimed
    );

    /// @dev Emitted when the contract's claim conditions are updated.
    event ClaimConditionsUpdated(uint256 indexed tokenId, ClaimCondition[] claimConditions, bool resetEligibility);

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                        The tokenId of the NFT to claim.
     *  @param quantity                       The quantity of NFTs to claim.
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
     *  @param tokenId                  The token ID for which to set mint conditions.
     *  @param phases                   Claim conditions in ascending order by `startTimestamp`.
     *
     *  @param resetClaimEligibility    Whether to reset `limitLastClaimTimestamp` and `limitMerkleProofClaim` values when setting new
     *                                  claim conditions.
     *
     */
    function setClaimConditions(
        uint256 tokenId,
        ClaimCondition[] calldata phases,
        bool resetClaimEligibility
    ) external;
}
