// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../extension/interface/IClaimCondition.sol";
import "../lib/MerkleProof.sol";

interface IDropWithTiers is IClaimCondition {
    struct AllowlistProof {
        bytes32[] proof;
        uint256 quantityLimitPerWallet;
        uint256 pricePerToken;
        address currency;
    }

    struct ClaimConditionForTier {
        string tier;
        ClaimCondition condition;
    }

    /// @dev Emitted when tokens are claimed via `claim`.
    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        string indexed tier,
        uint256 startTokenId,
        uint256 quantityClaimed
    );

    /// @dev Emitted when the contract's claim conditions are updated.
    event ClaimConditionUpdated(ClaimConditionForTier condition, bool resetEligibility);

    function claim(
        address receiver,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        AllowlistProof calldata allowlistProof,
        bytes memory data
    ) external payable;

    function setClaimConditions(ClaimConditionForTier memory condition, bool _resetClaimEligibility) external;
}
