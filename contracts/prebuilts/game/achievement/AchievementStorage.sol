// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAchievement } from "./IAchievement.sol";

library AchievementStorage {
    bytes32 public constant ACHIEVEMENT_STORAGE_POSITION = keccak256("achievement.storage");

    struct Data {
        mapping(bytes32 => IAchievement.AchievementInfo) achievementInfo;
        mapping(address => mapping(bytes32 => uint256)) claimCount;
    }

    function achievementStorage() internal pure returns (Data storage achievementData) {
        bytes32 position = ACHIEVEMENT_STORAGE_POSITION;
        assembly {
            achievementData.slot := position
        }
    }
}
