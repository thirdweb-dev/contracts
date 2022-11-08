// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../openzeppelin-presets/security/ReentrancyGuard.sol";
import "../eip/interface/IERC721.sol";

import "lib/forge-std/src/console.sol";
import "./interface/IStaking.sol";

abstract contract Staking721 is ReentrancyGuard, IStaking {
    uint256 public timeUnit;
    uint256 public rewardsPerUnitTime;
    address public nftCollection;

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;

    address[] public stakersArray;

    constructor(address _nftCollection) ReentrancyGuard() {
        require(address(_nftCollection) != address(0), "collection address 0");
        nftCollection = _nftCollection;
    }

    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        _stake(_tokenIds);
    }

    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        _withdraw(_tokenIds);
    }

    function claimRewards() external nonReentrant {
        _claimRewards();
    }

    function setTimeUnit(uint256 _timeUnit) external {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll();
        _setTimeUnit(_timeUnit);
    }

    function setRewardsPerUnitTime(uint256 _rewardsPerUnitTime) external {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll();
        _setRewardsPerUnitTime(_rewardsPerUnitTime);
    }

    function getStakeInfo(address _staker) public view virtual returns (uint256 _tokensStaked, uint256 _rewards) {
        _tokensStaked = stakers[_staker].amountStaked;
        _rewards = _availableRewards(_staker);
    }

    function _stake(uint256[] calldata _tokenIds) internal virtual {
        uint256 len = _tokenIds.length;
        require(len != 0, "Staking 0 tokens");

        if (stakers[msg.sender].amountStaked > 0) {
            _updateUnclaimedRewardsForStaker(msg.sender);
        } else {
            stakersArray.push(msg.sender);
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        for (uint256 i; i < len; ++i) {
            require(IERC721(nftCollection).ownerOf(_tokenIds[i]) == msg.sender, "Not owner");
            IERC721(nftCollection).transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakerAddress[_tokenIds[i]] = msg.sender;
        }
        stakers[msg.sender].amountStaked += len;
    }

    function _withdraw(uint256[] calldata _tokenIds) internal virtual {
        require(stakers[msg.sender].amountStaked > 0, "No staked tokens");

        _updateUnclaimedRewardsForStaker(msg.sender);

        uint256 len = _tokenIds.length;
        require(len != 0, "Withdrawing 0 tokens");

        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender, "Not staker");
            stakerAddress[_tokenIds[i]] = address(0);
            IERC721(nftCollection).transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
        stakers[msg.sender].amountStaked -= len;

        if (stakers[msg.sender].amountStaked == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == msg.sender) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1];
                    stakersArray.pop();
                }
            }
        }
    }

    function _claimRewards() internal virtual {
        uint256 rewards = stakers[msg.sender].unclaimedRewards + _calculateRewards(msg.sender);

        require(rewards != 0, "No rewards");

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;

        _mintRewards(msg.sender, rewards);
    }

    function _availableRewards(address _user) internal view virtual returns (uint256 _rewards) {
        if (stakers[_user].amountStaked == 0) {
            _rewards = stakers[_user].unclaimedRewards;
        } else {
            _rewards = stakers[_user].unclaimedRewards + _calculateRewards(_user);
        }
    }

    function _updateUnclaimedRewardsForAll() internal virtual {
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];

            uint256 rewards = _calculateRewards(user);
            stakers[user].unclaimedRewards += rewards;
            stakers[user].timeOfLastUpdate = block.timestamp;
        }
    }

    function _updateUnclaimedRewardsForStaker(address _staker) internal virtual {
        uint256 rewards = _calculateRewards(_staker);
        stakers[_staker].unclaimedRewards += rewards;
        stakers[_staker].timeOfLastUpdate = block.timestamp;
    }

    function _setTimeUnit(uint256 _timeUnit) internal virtual {
        timeUnit = _timeUnit;
    }

    function _setRewardsPerUnitTime(uint256 _rewardsPerUnitTime) internal virtual {
        rewardsPerUnitTime = _rewardsPerUnitTime;
    }

    function _calculateRewards(address _staker) internal view virtual returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];
        _rewards = ((((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked) * rewardsPerUnitTime) /
            timeUnit);
    }

    /// @dev Mint ERC20 rewards to the staker.
    function _mintRewards(address _staker, uint256 _rewards) internal virtual;

    /// @dev Returns whether staking related restrictions can be set in the given execution context.
    function _canSetStakeConditions() internal view virtual returns (bool);
}
