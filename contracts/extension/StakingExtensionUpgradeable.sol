// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "lib/forge-std/src/console.sol";
import "./interface/IStaking.sol";

abstract contract StakingExtensionUpgradeable is Initializable, IStaking {
    using SafeERC20 for IERC20;

    uint256 public timeUnit;
    uint256 public rewardsPerUnitTime;
    // uint256 public compoundingRate;
    IERC721 public nftCollection;

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;

    address[] public stakersArray;

    function __StakingExtension_init(IERC721 _nftCollection) internal onlyInitializing {
        require(address(_nftCollection) != address(0), "collection address 0");
        nftCollection = _nftCollection;
    }

    function stake(uint256[] calldata _tokenIds) external {
        if (stakers[msg.sender].amountStaked > 0) {
            _updateUnclaimedRewardsForStaker(msg.sender);
        } else {
            stakersArray.push(msg.sender);
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(nftCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");
            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakerAddress[_tokenIds[i]] = msg.sender;
        }
        stakers[msg.sender].amountStaked += len;
    }

    function withdraw(uint256[] calldata _tokenIds) external {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");

        _updateUnclaimedRewardsForStaker(msg.sender);

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);
            stakerAddress[_tokenIds[i]] = address(0);
            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
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

    function claimRewards() external {
        uint256 rewards = stakers[msg.sender].unclaimedRewards + _calculateRewards(msg.sender);

        require(rewards != 0, "no rewards");

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;

        _mintRewards(msg.sender, rewards);
    }

    function setRewardsPerUnitTime(uint256 _rewardsPerUnitTime) public {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll();
        rewardsPerUnitTime = _rewardsPerUnitTime;
    }

    function setTimeUnit(uint256 _timeUnit) public {
        if (!_canSetStakeConditions()) {
            revert("Not authorized");
        }

        _updateUnclaimedRewardsForAll();
        timeUnit = _timeUnit;
    }

    // function setCompoundingRate(uint256 _compoundingRate) public {
    //     if (!_canSetStakeConditions()) {
    //         revert("Not authorized");
    //     }

    //     _updateUnclaimedRewardsForAll();
    //     compoundingRate = _compoundingRate;
    // }

    function getStakeInfo(address _staker) public view returns (uint256 _tokensStaked, uint256 _rewards) {
        _tokensStaked = stakers[_staker].amountStaked;
        _rewards = _availableRewards(_staker);
    }

    function _availableRewards(address _user) internal view returns (uint256 _rewards) {
        if (stakers[_user].amountStaked == 0) {
            _rewards = stakers[_user].unclaimedRewards;
        } else {
            _rewards = stakers[_user].unclaimedRewards + _calculateRewards(_user);
        }
    }

    function _updateUnclaimedRewardsForAll() internal {
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];

            uint256 rewards = _calculateRewards(user);
            stakers[user].unclaimedRewards += rewards;
            stakers[user].timeOfLastUpdate = block.timestamp;
        }
    }

    function _updateUnclaimedRewardsForStaker(address _staker) internal {
        uint256 rewards = _calculateRewards(_staker);
        stakers[_staker].unclaimedRewards += rewards;
        stakers[_staker].timeOfLastUpdate = block.timestamp;
    }

    function _setRewardsPerUnitTime(uint256 _rewardsPerUnitTime) internal {
        rewardsPerUnitTime = _rewardsPerUnitTime;
    }

    function _setTimeUnit(uint256 _timeUnit) internal {
        timeUnit = _timeUnit;
    }

    // function _setCompoundingRate(uint256 _compoundingRate) internal {
    //     compoundingRate = _compoundingRate;
    // }

    function _calculateRewards(address _staker) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];
        _rewards = (((((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked)) * rewardsPerUnitTime) /
            timeUnit);
    }

    /// @dev Mint ERC20 rewards to the staker.
    function _mintRewards(address _staker, uint256 _rewards) internal virtual;

    /// @dev Returns whether staking related restrictions can be set in the given execution context.
    function _canSetStakeConditions() internal view virtual returns (bool);
}
