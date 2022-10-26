// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IStakeERC721 {
    /**
     *  @notice Conditions for staking.
     *
     *  @param minAmount                      Minimum number of tokens that must be staked (exactly 1 in case of ERC721)
     *
     *  @param minStakingDuration             Lock-in period to be eligible to claim rewards.
     *
     *  @param maxStakingDuration             Max time duration a user can stake for; no rewards after this.
     *                                        Will usually be type(uint256).max, but can be set based on the use-case.
     *
     *  @param timeUnit                       Time unit for calculation of rewards (i.e. per hour, per day, per week, etc.)
     *                                        Must be specified as - 1 seconds, 1 hours, 1 weeks, etc.
     *
     *  @param rewardsPerUnitTime             Rewards accumulated per unit of time (specified in timeUnit above)
     *
     *  @param compoundingRate                Rate at which rewardsPerUnitTime are compounded for the next time period.
     *
     *  @param rewardToken                    Address of the ERC20 token in which rewards are denominated.
     */
    struct StakeConditions {
        uint256 minAmount;
        uint256 minStakingDuration;
        uint256 maxStakingDuration;
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 compoundingRate;
        address rewardToken;
    }

    /**
     *  @notice Staked Token.
     *
     *  @param staker               Address of staker.
     *
     *  @param tokenId              Id of staked token.
     *
     *  @param timeOfLastUpdate     Unix timestamp at which rewards were last calculated for the token.
     */
    struct StakedToken {
        address staker;
        uint256 tokenId;
        uint256 timeOfLastUpdate;
    }

    /**
     *  @notice Staker Info.
     *
     *  @param amountStaked                   Total number of tokens staked by the staker.
     *
     *  @param stakedTokens                   List of tokens staked.
     *
     *  @param rewardsAccumulatedPerToken     Rewards accumulated per token based on staked timestamp.
     */
    struct StakerInfo {
        uint256 amountStaked;
        StakedToken[] stakedTokens;
        mapping(uint256 => uint256) rewardsAccumulatedPerToken;
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
     *  @notice Calculated total rewards accumulated so far for a given staker.
     *
     *  @param staker    Address for which to calculated rewards.
     */
    function calculateRewards(address staker) external view;
}
