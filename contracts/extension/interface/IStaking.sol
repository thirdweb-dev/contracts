// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IStaking {
    /**
     *  @notice Staker Info.
     *
     *  @param amountStaked         Total number of tokens staked by the staker.
     *
     *  @param timeOfLastUpdate     Last reward-update timestamp.
     *
     *  @param unclaimedRewards     Rewards accumulated but not claimed by user yet.
     */
    struct Staker {
        uint256 amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
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
    function getStakeInfo(address staker) external view returns (uint256 _tokensStaked, uint256 _rewards);
}
