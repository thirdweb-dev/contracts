// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IClaimConditionMultiPhase.sol";

interface IDrop is IClaimConditionMultiPhase {
    struct AllowlistProof {
        bytes32[] proof;
        uint256 maxQuantityInAllowlist;
    }

    /// @dev Emitted when an unauthorized caller tries to set claim conditions.
    error Drop__NotAuthorized();

    /// @notice Emitted when given currency or price is invalid.
    error Drop__InvalidCurrencyOrPrice(
        address givenCurrency,
        address requiredCurrency,
        uint256 givenPricePerToken,
        uint256 requiredPricePerToken
    );

    /// @notice Emitted when claiming invalid quantity of tokens.
    error Drop__InvalidQuantity();

    /// @notice Emitted when claiming given quantity will exceed max claimable supply.
    error Drop__ExceedMaxClaimableSupply(uint256 supplyClaimed, uint256 maxClaimableSupply);

    /// @notice Emitted when the current timestamp is invalid for claim.
    error Drop__CannotClaimYet(
        uint256 blockTimestamp,
        uint256 startTimestamp,
        uint256 lastClaimedAt,
        uint256 nextValidClaimTimestamp
    );

    /// @notice Emitted when given allowlist proof is invalid.
    error Drop__NotInWhitelist();

    /// @notice Emitted when allowlist spot is already used.
    error Drop__ProofClaimed();

    /// @notice Emitted when claiming more than allowed quantity in allowlist.
    error Drop__InvalidQuantityProof(uint256 maxQuantityInAllowlist);

    /// @notice Emitted when max claimable supply in given condition is less than supply claimed already.
    error Drop__MaxSupplyClaimedAlready(uint256 supplyClaimedAlready);

    /// @dev Emitted when tokens are claimed via `claim`.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 startTokenId,
        uint256 quantityClaimed
    );

    /// @dev Emitted when the contract's claim conditions are updated.
    event ClaimConditionsUpdated(ClaimCondition[] claimConditions, bool resetEligibility);

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
     *  @param phases                   Claim conditions in ascending order by `startTimestamp`.
     *
     *  @param resetClaimEligibility    Whether to reset `limitLastClaimTimestamp` and `limitMerkleProofClaim` values when setting new
     *                                  claim conditions.
     *
     */
    function setClaimConditions(ClaimCondition[] calldata phases, bool resetClaimEligibility) external;
}
