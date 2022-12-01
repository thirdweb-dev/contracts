// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../openzeppelin-presets/security/ReentrancyGuard.sol";
import "../eip/interface/IERC20.sol";
import "../lib/CurrencyTransferLib.sol";

import "./interface/IStaking20.sol";

/**
 *      note: This is a Beta release.
 */

abstract contract Staking20 is ReentrancyGuard, IStaking20 {
    /*///////////////////////////////////////////////////////////////
                            State variables / Mappings
    //////////////////////////////////////////////////////////////*/

    ///@dev Address of ERC20 contract -- staked tokens belong to this contract.
    address public token;

    /// @dev Unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.
    uint256 public timeUnit;

    ///@dev Rewards ratio is the number of reward tokens for a number of staked tokens, per unit of time.
    uint256 public rewardRatioNumerator;

    ///@dev Rewards ratio is the number of reward tokens for a number of staked tokens, per unit of time.
    uint256 public rewardRatioDenominator;

    ///@dev Mapping staker address to Staker struct. See {struct IStaking20.Staker}.
    mapping(address => Staker) public stakers;

    /// @dev List of accounts that have staked that token-id.
    address[] public stakersArray;

    constructor(address _token) ReentrancyGuard() {
        require(address(_token) != address(0), "address 0");
        token = _token;
    }

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice    Stake ERC20 Tokens.
     *
     *  @dev       See {_stake}. Override that to implement custom logic.
     *
     *  @param _amount    Amount to stake.
     */
    function stake(uint256 _amount) external nonReentrant {
        _stake(_amount);
    }

    /**
     *  @notice    Withdraw staked ERC20 tokens.
     *
     *  @dev       See {_withdraw}. Override that to implement custom logic.
     *
     *  @param _amount    Amount to withdraw.
     */
    function withdraw(uint256 _amount) external nonReentrant {
        _withdraw(_amount);
    }

    /**
     *  @notice    Claim accumulated rewards.
     *
     *  @dev       See {_claimRewards}. Override that to implement custom logic.
     *             See {_calculateRewards} for reward-calculation logic.
     */
    function claimRewards() external nonReentrant {
        _claimRewards();
    }

    /**
     *  @notice  Set time unit. Set as a number of seconds.
     *           Could be specified as -- x * 1 hours, x * 1 days, etc.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *  @param _timeUnit    New time unit.
     */
    function setTimeUnit(uint256 _timeUnit) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll();

        uint256 currentTimeUnit = timeUnit;
        _setTimeUnit(_timeUnit);

        emit UpdatedTimeUnit(currentTimeUnit, _timeUnit);
    }

    /**
     *  @notice  Set rewards per unit of time.
     *           Interpreted as (numerator/denominator) rewards per second/per day/etc based on time-unit.
     *
     *           For e.g., ratio of 1/20 would mean 1 reward token for every 20 tokens staked.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *  @param _numerator    Reward ratio numerator.
     *  @param _denominator  Reward ratio denominator.
     */
    function setRewardRatio(uint256 _numerator, uint256 _denominator) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll();

        uint256 currentNumerator = rewardRatioNumerator;
        uint256 currentDenominator = rewardRatioDenominator;
        _setRewardRatio(_numerator, _denominator);

        emit UpdatedRewardRatio(currentNumerator, _numerator, currentDenominator, _denominator);
    }

    /**
     *  @notice View amount staked and rewards for a user.
     *
     *  @param _staker          Address for which to calculated rewards.
     *  @return _tokensStaked   Amount of tokens staked.
     *  @return _rewards        Available reward amount.
     */
    function getStakeInfo(address _staker) public view virtual returns (uint256 _tokensStaked, uint256 _rewards) {
        _tokensStaked = stakers[_staker].amountStaked;
        _rewards = _availableRewards(_staker);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Staking logic. Override to add custom logic.
    function _stake(uint256 _amount) internal virtual {
        require(_amount != 0, "Staking 0 tokens");
        address _token = token;

        if (stakers[msg.sender].amountStaked > 0) {
            _updateUnclaimedRewardsForStaker(msg.sender);
        } else {
            stakersArray.push(msg.sender);
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }

        CurrencyTransferLib.transferCurrency(_token, msg.sender, address(this), _amount);

        stakers[msg.sender].amountStaked += _amount;

        emit TokensStaked(msg.sender, _amount);
    }

    /// @dev Withdraw logic. Override to add custom logic.
    function _withdraw(uint256 _amount) internal virtual {
        uint256 _amountStaked = stakers[msg.sender].amountStaked;
        require(_amount != 0, "Withdrawing 0 tokens");
        require(_amountStaked >= _amount, "Withdrawing more than staked");

        _updateUnclaimedRewardsForStaker(msg.sender);

        if (_amountStaked == _amount) {
            address[] memory _stakersArray = stakersArray;
            for (uint256 i = 0; i < _stakersArray.length; ++i) {
                if (_stakersArray[i] == msg.sender) {
                    stakersArray[i] = stakersArray[_stakersArray.length - 1];
                    stakersArray.pop();
                    break;
                }
            }
        }
        stakers[msg.sender].amountStaked -= _amount;

        CurrencyTransferLib.transferCurrency(token, address(this), msg.sender, _amount);

        emit TokensWithdrawn(msg.sender, _amount);
    }

    /// @dev Logic for claiming rewards. Override to add custom logic.
    function _claimRewards() internal virtual {
        uint256 rewards = stakers[msg.sender].unclaimedRewards + _calculateRewards(msg.sender);

        require(rewards != 0, "No rewards");

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;

        _mintRewards(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @dev View available rewards for a user.
    function _availableRewards(address _staker) internal view virtual returns (uint256 _rewards) {
        if (stakers[_staker].amountStaked == 0) {
            _rewards = stakers[_staker].unclaimedRewards;
        } else {
            _rewards = stakers[_staker].unclaimedRewards + _calculateRewards(_staker);
        }
    }

    /// @dev Update unclaimed rewards for all users. Called when setting timeUnit or rewardsPerUnitTime.
    function _updateUnclaimedRewardsForAll() internal virtual {
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i = 0; i < len; ++i) {
            address _staker = _stakers[i];

            uint256 rewards = _calculateRewards(_staker);
            stakers[_staker].unclaimedRewards += rewards;
            stakers[_staker].timeOfLastUpdate = block.timestamp;
        }
    }

    /// @dev Update unclaimed rewards for a users. Called for every state change for a user.
    function _updateUnclaimedRewardsForStaker(address _staker) internal virtual {
        uint256 rewards = _calculateRewards(_staker);
        stakers[_staker].unclaimedRewards += rewards;
        stakers[_staker].timeOfLastUpdate = block.timestamp;
    }

    /// @dev Set time unit in seconds.
    function _setTimeUnit(uint256 _timeUnit) internal virtual {
        timeUnit = _timeUnit;
    }

    /// @dev Set reward ratio per unit time.
    function _setRewardRatio(uint256 _numerator, uint256 _denominator) internal virtual {
        require(_denominator != 0, "divide by 0");
        rewardRatioNumerator = _numerator;
        rewardRatioDenominator = _denominator;
    }

    /// @dev Reward calculation logic. Override to implement custom logic.
    function _calculateRewards(address _staker) internal view virtual returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];

        _rewards = (((((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked) * rewardRatioNumerator) /
            timeUnit) / rewardRatioDenominator);
    }

    /**
     *  @dev    Mint/Transfer ERC20 rewards to the staker. Must override.
     *
     *  @param _staker    Address for which to calculated rewards.
     *  @param _rewards   Amount of tokens to be given out as reward.
     *
     *  For example, override as below to mint ERC20 rewards:
     *
     * ```
     *  function _mintRewards(address _staker, uint256 _rewards) internal override {
     *
     *      TokenERC20(rewardTokenAddress).mintTo(_staker, _rewards);
     *
     *  }
     * ```
     */
    function _mintRewards(address _staker, uint256 _rewards) internal virtual;

    /**
     *  @dev    Returns whether staking restrictions can be set in given execution context.
     *          Must override.
     *
     *
     *  For example, override as below to restrict access to admin:
     *
     * ```
     *  function _canSetStakeConditions() internal override {
     *
     *      return msg.sender == adminAddress;
     *
     *  }
     * ```
     */
    function _canSetStakeConditions() internal view virtual returns (bool);
}
