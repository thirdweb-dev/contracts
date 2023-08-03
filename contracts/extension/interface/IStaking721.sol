// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

interface IStaking721 {
    /// @dev Emitted when a set of token-ids are staked.
    event TokensStaked(address indexed staker, uint256[] indexed tokenIds);

    /// @dev Emitted when a set of staked token-ids are withdrawn.
    event TokensWithdrawn(address indexed staker, uint256[] indexed tokenIds);

    /// @dev Emitted when a staker claims staking rewards.
    event RewardsClaimed(address indexed staker, uint256 rewardAmount);

    /// @dev Emitted when contract admin updates timeUnit.
    event UpdatedTimeUnit(uint256 oldTimeUnit, uint256 newTimeUnit);

    /// @dev Emitted when contract admin updates rewardsPerUnitTime.
    event UpdatedRewardsPerUnitTime(uint256 oldRewardsPerUnitTime, uint256 newRewardsPerUnitTime);

    /**
     *  @notice Staker Info.
     *
     *  @param amountStaked             Total number of tokens staked by the staker.
     *
     *  @param timeOfLastUpdate         Last reward-update timestamp.
     *
     *  @param unclaimedRewards         Rewards accumulated but not claimed by user yet.
     *
     *  @param conditionIdOflastUpdate  Condition-Id when rewards were last updated for user.
     */
    struct Staker {
        uint64 amountStaked;
        uint64 conditionIdOflastUpdate;
        uint128 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    /**
     *  @notice Staking Condition.
     *
     *  @param timeUnit           Unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.
     *
     *  @param rewardsPerUnitTime Rewards accumulated per unit of time.
     *
     *  @param startTimestamp     Condition start timestamp.
     *
     *  @param endTimestamp       Condition end timestamp.
     */
    struct StakingCondition {
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /**
     *  @notice Stake ERC721 Tokens.
     *
     *  @param tokenIds    List of tokens to stake.
     */
    function stake(uint256[] calldata tokenIds) external;

    /**
     *  @notice Withdraw staked tokens.
     *
     *  @param tokenIds    List of tokens to withdraw.
     */
    function withdraw(uint256[] calldata tokenIds) external;

    /**
     *  @notice Claim accumulated rewards.
     */
    function claimRewards() external;

    /**
     *  @notice View amount staked and total rewards for a user.
     *
     *  @param staker    Address for which to calculated rewards.
     */
    function getStakeInfo(address staker) external view returns (uint256[] memory _tokensStaked, uint256 _rewards);
}
