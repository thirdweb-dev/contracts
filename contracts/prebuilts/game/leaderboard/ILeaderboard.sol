// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGameSignature } from "../utils/IGameSignature.sol";
import { IRulesEngine } from "../../../../contracts/extension/interface/IRulesEngine.sol";

interface ILeaderboard {
    struct LeaderboardScore {
        address player;
        uint256 score;
    }

    struct LeaderboardInfo {
        string name;
        bytes32[] rules;
        address[] players;
    }

    event CreateLeaderboard(uint256 indexed leaderboard, LeaderboardInfo leaderboardInfo);
    event UpdateLeaderboardInfo(uint256 indexed leaderboard, LeaderboardInfo leaderboardInfo);
    event AddPlayerToLeaderboard(uint256 indexed leaderboard, address player);
    event RemovePlayerFromLeaderboard(uint256 indexed leaderboard, address player);

    function createLeaderboard(uint256 id, LeaderboardInfo calldata leaderboardInfo) external;

    function updateLeaderboardInfo(uint256 id, LeaderboardInfo calldata leaderboardInfo) external;

    function createLeaderboardWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function updateLeaderboardInfoWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature)
        external;

    function getLeaderboardInfo(uint256 id) external view returns (LeaderboardInfo memory);
}
