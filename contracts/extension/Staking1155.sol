// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../openzeppelin-presets/security/ReentrancyGuard.sol";
import "../eip/interface/IERC1155.sol";

import "./interface/IStaking1155.sol";

/**
 *      note: This is a Beta release.
 */

abstract contract Staking1155 is ReentrancyGuard, IStaking1155 {
    /*///////////////////////////////////////////////////////////////
                            State variables / Mappings
    //////////////////////////////////////////////////////////////*/

    ///@dev Address of ERC1155 contract -- staked tokens belong to this contract.
    address public edition;

    /// @dev Default unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.
    uint256 public defaultTimeUnit;

    ///@dev Default rewards accumulated per unit of time.
    uint256 public defaultRewardsPerUnitTime;

    ///@dev List of token-ids ever staked.
    uint256[] public indexedTokens;

    ///@dev Mapping from token-id to whether it is indexed or not.
    mapping(uint256 => bool) public isIndexed;

    /// @dev Mapping from token-id to unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.
    mapping(uint256 => uint256) public timeUnit;

    ///@dev Mapping from token-id to rewards accumulated per unit of time.
    mapping(uint256 => uint256) public rewardsPerUnitTime;

    ///@dev Mapping from token-id and staker address to Staker struct. See {struct IStaking1155.Staker}.
    mapping(uint256 => mapping(address => Staker)) public stakers;

    /// @dev Mapping from token-id to list of accounts that have staked that token-id.
    mapping(uint256 => address[]) public stakersArray;

    constructor(address _edition) ReentrancyGuard() {
        require(address(_edition) != address(0), "address 0");
        edition = _edition;
    }

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice    Stake ERC721 Tokens.
     *
     *  @dev       See {_stake}. Override that to implement custom logic.
     *
     *  @param _tokenId   ERC1155 token-id to stake.
     *  @param _amount    Amount to stake.
     */
    function stake(uint256 _tokenId, uint256 _amount) external nonReentrant {
        _stake(_tokenId, _amount);
    }

    /**
     *  @notice    Withdraw staked tokens.
     *
     *  @dev       See {_withdraw}. Override that to implement custom logic.
     *
     *  @param _tokenId   ERC1155 token-id to withdraw.
     *  @param _amount    Amount to withdraw.
     */
    function withdraw(uint256 _tokenId, uint256 _amount) external nonReentrant {
        _withdraw(_tokenId, _amount);
    }

    /**
     *  @notice    Claim accumulated rewards.
     *
     *  @dev       See {_claimRewards}. Override that to implement custom logic.
     *             See {_calculateRewards} for reward-calculation logic.
     *
     *  @param _tokenId   Staked token Id.
     */
    function claimRewards(uint256 _tokenId) external nonReentrant {
        _claimRewards(_tokenId);
    }

    /**
     *  @notice  Set time unit. Set as a number of seconds.
     *           Could be specified as -- x * 1 hours, x * 1 days, etc.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _tokenId     ERC1155 token Id.
     *  @param _timeUnit    New time unit.
     */
    function setTimeUnit(uint256 _tokenId, uint256 _timeUnit) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll(_tokenId);

        uint256 currentTimeUnit = timeUnit[_tokenId];
        _setTimeUnit(_tokenId, _timeUnit);

        emit UpdatedTimeUnit(_tokenId, currentTimeUnit, _timeUnit);
    }

    /**
     *  @notice  Set rewards per unit of time.
     *           Interpreted as x rewards per second/per day/etc based on time-unit.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _tokenId               ERC1155 token Id.
     *  @param _rewardsPerUnitTime    New rewards per unit time.
     */
    function setRewardsPerUnitTime(uint256 _tokenId, uint256 _rewardsPerUnitTime) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll(_tokenId);

        uint256 currentRewardsPerUnitTime = rewardsPerUnitTime[_tokenId];
        _setRewardsPerUnitTime(_tokenId, _rewardsPerUnitTime);

        emit UpdatedRewardsPerUnitTime(_tokenId, currentRewardsPerUnitTime, _rewardsPerUnitTime);
    }

    /**
     *  @notice  Set time unit. Set as a number of seconds.
     *           Could be specified as -- x * 1 hours, x * 1 days, etc.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *  @param _defaultTimeUnit    New time unit.
     */
    function setDefaultTimeUnit(uint256 _defaultTimeUnit) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        uint256[] memory _indexedTokens = indexedTokens;

        for (uint256 i = 0; i < _indexedTokens.length; i++) {
            _updateUnclaimedRewardsForAll(_indexedTokens[i]);
        }

        uint256 currentDefaultTimeUnit = defaultTimeUnit;
        _setDefaultTimeUnit(_defaultTimeUnit);

        emit UpdatedDefaultTimeUnit(currentDefaultTimeUnit, _defaultTimeUnit);
    }

    /**
     *  @notice  Set rewards per unit of time.
     *           Interpreted as x rewards per second/per day/etc based on time-unit.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *  @param _defaultRewardsPerUnitTime    New rewards per unit time.
     */
    function setDefaultRewardsPerUnitTime(uint256 _defaultRewardsPerUnitTime) external virtual {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        uint256[] memory _indexedTokens = indexedTokens;

        for (uint256 i = 0; i < _indexedTokens.length; i++) {
            _updateUnclaimedRewardsForAll(_indexedTokens[i]);
        }

        uint256 currentDefaultRewardsPerUnitTime = defaultRewardsPerUnitTime;
        _setDefaultRewardsPerUnitTime(_defaultRewardsPerUnitTime);

        emit UpdatedDefaultRewardsPerUnitTime(currentDefaultRewardsPerUnitTime, _defaultRewardsPerUnitTime);
    }

    /**
     *  @notice View amount staked and rewards for a user, for a given token-id.
     *
     *  @param _staker          Address for which to calculated rewards.
     *  @return _tokensStaked   Amount of tokens staked for given token-id.
     *  @return _rewards        Available reward amount.
     */
    function getStakeInfoForToken(uint256 _tokenId, address _staker)
        public
        view
        virtual
        returns (uint256 _tokensStaked, uint256 _rewards)
    {
        _tokensStaked = stakers[_tokenId][_staker].amountStaked;
        _rewards = _availableRewards(_tokenId, _staker);
    }

    /**
     *  @notice View all tokens staked and total rewards for a user.
     *
     *  @param _staker          Address for which to calculated rewards.
     *  @return _tokensStaked   List of token-ids staked.
     *  @return _tokenAmounts   Amount of each token-id staked.
     *  @return _totalRewards   Total rewards available.
     */
    function getStakeInfo(address _staker)
        public
        view
        virtual
        returns (
            uint256[] memory _tokensStaked,
            uint256[] memory _tokenAmounts,
            uint256 _totalRewards
        )
    {
        uint256[] memory _indexedTokens = indexedTokens;
        uint256[] memory _stakedAmounts = new uint256[](_indexedTokens.length);
        uint256 indexedTokenCount = _indexedTokens.length;
        uint256 stakerTokenCount = 0;

        for (uint256 i = 0; i < indexedTokenCount; i++) {
            _stakedAmounts[i] = stakers[_indexedTokens[i]][_staker].amountStaked;
            if (_stakedAmounts[i] > 0) stakerTokenCount += 1;
        }

        _tokensStaked = new uint256[](stakerTokenCount);
        _tokenAmounts = new uint256[](stakerTokenCount);
        uint256 count = 0;
        for (uint256 i = 0; i < indexedTokenCount; i++) {
            if (_stakedAmounts[i] > 0) {
                _tokensStaked[count] = _indexedTokens[i];
                _tokenAmounts[count] = _stakedAmounts[i];
                _totalRewards += _availableRewards(_indexedTokens[i], _staker);
                count += 1;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Staking logic. Override to add custom logic.
    function _stake(uint256 _tokenId, uint256 _amount) internal virtual {
        require(_amount != 0, "Staking 0 tokens");
        address _edition = edition;

        if (stakers[_tokenId][msg.sender].amountStaked > 0) {
            _updateUnclaimedRewardsForStaker(_tokenId, msg.sender);
        } else {
            stakersArray[_tokenId].push(msg.sender);
            stakers[_tokenId][msg.sender].timeOfLastUpdate = block.timestamp;
        }

        require(
            IERC1155(_edition).balanceOf(msg.sender, _tokenId) >= _amount &&
                IERC1155(_edition).isApprovedForAll(msg.sender, address(this)),
            "Not balance or approved"
        );
        IERC1155(_edition).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        // stakerAddress[_tokenIds[i]] = msg.sender;
        stakers[_tokenId][msg.sender].amountStaked += _amount;

        if (!isIndexed[_tokenId]) {
            isIndexed[_tokenId] = true;
            indexedTokens.push(_tokenId);
        }

        emit TokensStaked(msg.sender, _tokenId, _amount);
    }

    /// @dev Withdraw logic. Override to add custom logic.
    function _withdraw(uint256 _tokenId, uint256 _amount) internal virtual {
        uint256 _amountStaked = stakers[_tokenId][msg.sender].amountStaked;
        require(_amount != 0, "Withdrawing 0 tokens");
        require(_amountStaked >= _amount, "Withdrawing more than staked");

        _updateUnclaimedRewardsForStaker(_tokenId, msg.sender);

        if (_amountStaked == _amount) {
            address[] memory _stakersArray = stakersArray[_tokenId];
            for (uint256 i = 0; i < _stakersArray.length; ++i) {
                if (_stakersArray[i] == msg.sender) {
                    stakersArray[_tokenId][i] = stakersArray[_tokenId][_stakersArray.length - 1];
                    stakersArray[_tokenId].pop();
                    break;
                }
            }
        }
        stakers[_tokenId][msg.sender].amountStaked -= _amount;

        IERC1155(edition).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");

        emit TokensWithdrawn(msg.sender, _tokenId, _amount);
    }

    /// @dev Logic for claiming rewards. Override to add custom logic.
    function _claimRewards(uint256 _tokenId) internal virtual {
        uint256 rewards = stakers[_tokenId][msg.sender].unclaimedRewards + _calculateRewards(_tokenId, msg.sender);

        require(rewards != 0, "No rewards");

        stakers[_tokenId][msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[_tokenId][msg.sender].unclaimedRewards = 0;

        _mintRewards(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @dev View available rewards for a user.
    function _availableRewards(uint256 _tokenId, address _user) internal view virtual returns (uint256 _rewards) {
        if (stakers[_tokenId][_user].amountStaked == 0) {
            _rewards = stakers[_tokenId][_user].unclaimedRewards;
        } else {
            _rewards = stakers[_tokenId][_user].unclaimedRewards + _calculateRewards(_tokenId, _user);
        }
    }

    /// @dev Update unclaimed rewards for all users. Called when setting timeUnit or rewardsPerUnitTime.
    function _updateUnclaimedRewardsForAll(uint256 _tokenId) internal virtual {
        address[] memory _stakers = stakersArray[_tokenId];
        uint256 len = _stakers.length;
        for (uint256 i = 0; i < len; ++i) {
            address user = _stakers[i];

            uint256 rewards = _calculateRewards(_tokenId, user);
            stakers[_tokenId][user].unclaimedRewards += rewards;
            stakers[_tokenId][user].timeOfLastUpdate = block.timestamp;
        }
    }

    /// @dev Update unclaimed rewards for a users. Called for every state change for a user.
    function _updateUnclaimedRewardsForStaker(uint256 _tokenId, address _staker) internal virtual {
        uint256 rewards = _calculateRewards(_tokenId, _staker);
        stakers[_tokenId][_staker].unclaimedRewards += rewards;
        stakers[_tokenId][_staker].timeOfLastUpdate = block.timestamp;
    }

    /// @dev Set time unit in seconds.
    function _setTimeUnit(uint256 _tokenId, uint256 _timeUnit) internal virtual {
        timeUnit[_tokenId] = _timeUnit;
    }

    /// @dev Set rewards per unit time.
    function _setRewardsPerUnitTime(uint256 _tokenId, uint256 _rewardsPerUnitTime) internal virtual {
        rewardsPerUnitTime[_tokenId] = _rewardsPerUnitTime;
    }

    /// @dev Set time unit in seconds.
    function _setDefaultTimeUnit(uint256 _defaultTimeUnit) internal virtual {
        defaultTimeUnit = _defaultTimeUnit;
    }

    /// @dev Set rewards per unit time.
    function _setDefaultRewardsPerUnitTime(uint256 _defaultRewardsPerUnitTime) internal virtual {
        defaultRewardsPerUnitTime = _defaultRewardsPerUnitTime;
    }

    /// @dev Reward calculation logic. Override to implement custom logic.
    function _calculateRewards(uint256 _tokenId, address _staker) internal view virtual returns (uint256 _rewards) {
        Staker memory staker = stakers[_tokenId][_staker];
        uint256 _timeUnit = timeUnit[_tokenId];
        uint256 _rewardsPerUnitTime = rewardsPerUnitTime[_tokenId];

        if (_timeUnit == 0) _timeUnit = defaultTimeUnit;
        if (_rewardsPerUnitTime == 0) _rewardsPerUnitTime = defaultRewardsPerUnitTime;

        _rewards = ((((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked) * _rewardsPerUnitTime) /
            _timeUnit);
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
