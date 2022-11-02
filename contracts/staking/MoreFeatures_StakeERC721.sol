// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "lib/forge-std/src/console.sol";

contract StakeERC721 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     *  @notice Interface to describe reward amounts accumulated or unclaimed for every token for a staker.
     *
     *  @param assetContract The contract address of the asset.
     *  @param rewardAmount  Reward amount per hour (in wei or the smallest unit of asset).
     */
    struct RewardToken {
        address assetContract;
        uint256 rewardAmount;
    }

    // Interfaces for ERC20 and ERC721
    RewardToken[] public rewardTokens;
    IERC721 public immutable nftCollection;
    uint256 public totalRewardTokens;

    // Staker info
    struct Staker {
        // Amount of ERC721 Tokens staked
        uint256 amountStaked;
        // Last time of details update for this User
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256[] unclaimedRewards;
    }

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;
    // Mapping of Token Id to staker. Made for the SC to remeber
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

    address[] public stakersArray;

    // Constructor function
    constructor(IERC721 _nftCollection, RewardToken[] memory _rewardTokens) {
        require(address(_nftCollection) != address(0), "collection address 0");
        nftCollection = _nftCollection;

        uint256 rewardTokenCount = _rewardTokens.length;
        require(rewardTokenCount != 0, "no reward tokens");

        for (uint256 i = 0; i < rewardTokenCount; i++) {
            require(_rewardTokens[i].assetContract != address(0), "reward address 0");
            require(_rewardTokens[i].rewardAmount != 0, "zero amount");

            rewardTokens.push(_rewardTokens[i]);
        }

        totalRewardTokens = rewardTokenCount;
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // For every new Token Id in param transferFrom user to this Smart Contract,
    // increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        uint256 rewardsLen = rewardTokens.length;
        if (stakers[msg.sender].amountStaked > 0) {
            uint256[] memory rewards = calculateRewards(msg.sender);
            for (uint256 i = 0; i < rewards.length; i++) {
                stakers[msg.sender].unclaimedRewards[i] += rewards[i];
            }
        } else {
            stakersArray.push(msg.sender);
            for (uint256 i = 0; i < rewardsLen; i++) {
                stakers[msg.sender].unclaimedRewards.push(0);
            }
        }
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(nftCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");
            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakerAddress[_tokenIds[i]] = msg.sender;
        }
        stakers[msg.sender].amountStaked += len;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Check if user has any ERC721 Tokens Staked and if he tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards and for each
    // ERC721 Token in param: check if msg.sender is the original staker, decrement
    // the amountStaked of the user and transfer the ERC721 token back to them
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");

        uint256[] memory rewards = calculateRewards(msg.sender);
        for (uint256 i = 0; i < rewards.length; i++) {
            stakers[msg.sender].unclaimedRewards[i] += rewards[i];
        }

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);
            stakerAddress[_tokenIds[i]] = address(0);
            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
        stakers[msg.sender].amountStaked -= len;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        if (stakers[msg.sender].amountStaked == 0) {
            for (uint256 i; i < stakersArray.length; ++i) {
                if (stakersArray[i] == msg.sender) {
                    stakersArray[i] = stakersArray[stakersArray.length - 1];
                    stakersArray.pop();
                }
            }
        }
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {
        RewardToken[] memory _rewards = rewardTokens;
        uint256[] memory _unclaimedRewards = stakers[msg.sender].unclaimedRewards;
        uint256[] memory _newRewards = calculateRewards(msg.sender);

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;

        for (uint256 i = 0; i < _rewards.length; i++) {
            stakers[msg.sender].unclaimedRewards[i] = 0;

            IERC20(_rewards[i].assetContract).safeTransfer(msg.sender, _unclaimedRewards[i] + _newRewards[i]);
        }
    }

    // Set the rewardsPerHour variable
    // Because the rewards are calculated passively, the owner has to first update the rewards
    // to all the stakers, witch could result in very heavy load and expensive transactions or
    // even reverting due to reaching the gas limit per block. Redesign incoming to bound loop.
    function setRewardsPerHour(uint256[] memory _newValues) public onlyOwner {
        address[] memory _stakers = stakersArray;
        uint256 len = _stakers.length;
        for (uint256 i; i < len; ++i) {
            address user = _stakers[i];

            uint256[] memory rewards = calculateRewards(user);
            for (uint256 j = 0; j < rewards.length; j++) {
                stakers[user].unclaimedRewards[j] += rewards[j];
            }

            stakers[user].timeOfLastUpdate = block.timestamp;
        }
        for (uint256 i = 0; i < _newValues.length; i++) {
            rewardTokens[i].rewardAmount += _newValues[i];
        }
    }

    //////////
    // View //
    //////////

    function userStakeInfo(address _user)
        public
        view
        returns (uint256 _tokensStaked, RewardToken[] memory _availableRewards)
    {
        return (stakers[_user].amountStaked, availableRewards(_user));
    }

    function availableRewards(address _user) internal view returns (RewardToken[] memory) {
        RewardToken[] memory _rewards = rewardTokens;
        uint256[] memory _unclaimedRewards = stakers[_user].unclaimedRewards;
        uint256[] memory _newRewards = calculateRewards(_user);

        if (stakers[_user].amountStaked == 0) {
            for (uint256 i = 0; i < _rewards.length; i++) {
                _rewards[i].rewardAmount = _unclaimedRewards[i];
            }
        } else {
            for (uint256 i = 0; i < _rewards.length; i++) {
                _rewards[i].rewardAmount = _unclaimedRewards[i] + _newRewards[i];
            }
        }

        return _rewards;
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker) internal view returns (uint256[] memory _rewards) {
        Staker memory staker = stakers[_staker];

        RewardToken[] memory _rewardTokens = rewardTokens;
        _rewards = new uint256[](_rewardTokens.length);

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _rewards[i] = (((((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked)) *
                _rewardTokens[i].rewardAmount) / 3600);
        }
    }
}
