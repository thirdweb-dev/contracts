// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGameSignature } from "../utils/IGameSignature.sol";

interface IReward {
    enum RewardType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct RewardInfo {
        address rewardAddress;
        RewardType rewardType;
        uint256 rewardTokenId;
        uint256 rewardAmount;
    }

    event RegisterReward(string indexed identifier, RewardInfo rewardInfo);
    event UnregisterReward(string indexed identifier);
    event ClaimReward(address indexed receiver, string indexed identifier, RewardInfo rewardInfo);

    function registerReward(string memory identifier, RewardInfo calldata rewardInfo) external;

    function unregisterReward(string memory identifier) external;

    function claimReward(address receiver, string memory identifier) external;

    function registerRewardWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function unregisterRewardWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function claimRewardWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function getRewardInfo(string calldata identifier) external view returns (RewardInfo memory rewardInfo);
}
