// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../lib/TWBitMaps.sol";
import "./IClaimCondition.sol";

/**
 *  Thirdweb's 'Drop' contracts are distribution mechanisms for tokens.
 *
 *  A contract admin (i.e. a holder of `DEFAULT_ADMIN_ROLE`) can set a series of claim conditions,
 *  ordered by their respective `startTimestamp`. A claim condition defines criteria under which
 *  accounts can mint tokens. Claim conditions can be overwritten or added to by the contract admin.
 *  At any moment, there is only one active claim condition.
 */

interface IClaimConditionsSinglePhase is IClaimCondition {
    event ClaimConditionUpdated(ClaimCondition claimConditions, bool resetClaimEligibility);

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param phase                   Claim conditions in ascending order by `startTimestamp`.
     *
     *  @param resetClaimEligibility    Whether to reset `limitLastClaimTimestamp` and `limitMerkleProofClaim` values when setting new
     *                                  claim conditions.
     *
     */
    function setClaimConditions(ClaimCondition calldata phase, bool resetClaimEligibility) external;
}
