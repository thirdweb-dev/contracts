// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGameSignature } from "../utils/IGameSignature.sol";
import { IReward } from "../reward/IReward.sol";

interface IAchievement {
    struct AchievementInfo {
        bool isActive;
        bool canOnlyClaimOnce;
        string rewardId;
    }

    event CreateAchievement(bytes32 indexed identifier, AchievementInfo achievementInfo);
    event UpdateAchievement(bytes32 indexed identifier, AchievementInfo achievementInfo);
    event DeleteAchievement(bytes32 indexed identifier);
    event ClaimAchievement(address indexed receiver, bytes32 indexed identifier, AchievementInfo achievementInfo);

    function createAchievement(string calldata identifier, AchievementInfo calldata achievementInfo) external;

    function updateAchievement(string calldata identifier, AchievementInfo calldata achievementInfo) external;

    function deleteAchievement(string calldata identifier) external;

    function claimAchievement(address receiver, string calldata identifier) external;

    function createAchievementWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function updateAchievementWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function deleteAchievementWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function claimAchievementWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function getAchievementInfo(string calldata identifier)
        external
        view
        returns (AchievementInfo memory achievementInfo);

    function getAchievementClaimCount(address player, string calldata identifier) external view returns (uint256 count);
}
