// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  `LazyMintERC20` is an ERC 20 contract.
 *
 *  The module admin can create claim conditions with non-overlapping time windows,
 *  and accounts can claim the tokens, in a given time window, according to restrictions
 *  defined in that time window's claim conditions.
 */

interface ILazyMintERC20 {
    
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
     *  @param claimConditionAtIndex      The claim conditions at a given uid. Claim conditions
     *                                    are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param nextValidTimestampForClaim Account => uid for a claim condition => timestamp after
     *                                    which the account can claim tokens again.
     */
    struct ClaimConditions {
        uint256 totalConditionCount;
        uint256 timstampLimitIndex;
        mapping(uint256 => ClaimCondition) claimConditionAtIndex;
        mapping(address => mapping(uint256 => uint256)) timestampOfLastClaim;
    }

    /// @dev Emitted when tokens are claimed.
    event ClaimedTokens(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 quantityClaimed
    );

    /// @dev Emitted when new claim conditions are set.
    event NewClaimConditions(ClaimCondition[] claimConditions);

    /// @dev Emitted when a new primary sale recipient is set.
    event NewPrimarySaleRecipient(address indexed recipient);

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeUpdates(address platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Emitted when transfers are set as restricted / not-restricted.
    event TransfersRestricted(bool restricted);

    /// @dev Emitted when royalty info is updated.
    event RoyaltyUpdated(address newRoyaltyRecipient, uint256 newRoyaltyBps);
    
    /// @dev Emitted when the contract receives ether.
    event EtherReceived(address sender, uint256 amount);
    
    /// @dev Emitted when accrued royalties are withdrawn from the contract.
    event FundsWithdrawn(
        address indexed paymentReceiver,
        address feeRecipient,
        uint256 totalAmount,
        uint256 feeCollected
    );

    /**
     *  @notice Lets an account claim a given quantity of tokens.
     *
     *  @param receiver The receiver of the NFTs to claim.
     *  @param quantity The quantity of tokens to claim.
     *  @param proof   The proof required to prove the account's inclusion in the merkle root whitelist
     *                  of the mint conditions that apply.
     */
    function claim(address receiver, uint256 quantity, bytes32[] calldata proof) external payable;

    /**
     *  @notice Lets a module admin set claim conditions.
     *
     *  @param conditions       Mint conditions in ascending order by `startTimestamp`.
     *  @param resetRestriction Whether to reset (if `true`) or update (if `false`) the current claim conditions.
     */
    function setClaimConditions(ClaimCondition[] calldata conditions, bool resetRestriction) external;
}
