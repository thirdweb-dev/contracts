// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../interfaces/staking/IStakeERC721.sol";

contract StakeERC721 is IStakeERC721 {
    /**
     *  @notice Stake ERC721 Tokens.
     *
     *  @param tokenIds    List of tokens to stake.
     */
    function stake(uint256[] calldata tokenIds) external {}

    /**
     *  @notice Withdraw staked tokens.
     *
     *  @param tokenIds    List of tokens to withdraw.
     */
    function withdraw(uint256[] calldata tokenIds) external {}

    /**
     *  @notice Claim accumulated rewards.
     */
    function claimRewards() external {}

    /**
     *  @notice Calculated total rewards accumulated so far for a given staker.
     *
     *  @param staker    Address for which to calculated rewards.
     */
    function calculateRewards(address staker) external view {}
}
