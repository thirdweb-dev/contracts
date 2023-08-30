// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ILeaderboard } from "./ILeaderboard.sol";

library LeaderboardStorage {
    bytes32 public constant LEADERBOARD_STORAGE_POSITION = keccak256("leaderboard.storage");

    struct Data {
        mapping(uint256 => ILeaderboard.LeaderboardInfo) leaderboardInfo;
        uint256 leaderboardCount;
    }

    function leaderboardStorage() internal pure returns (Data storage leaderboardData) {
        bytes32 position = LEADERBOARD_STORAGE_POSITION;
        assembly {
            leaderboardData.slot := position
        }
    }
}
