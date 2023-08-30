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

    enum SortOrder {
        None,
        Ascending,
        Descending
    }

    event CreateLeaderboard(uint256 indexed leaderboardIndex, LeaderboardInfo leaderboardInfo);
    event UpdateLeaderboardInfo(uint256 indexed leaderboardIndex, LeaderboardInfo leaderboardInfo);
    event AddPlayerToLeaderboard(uint256 indexed leaderboardIndex, address player);
    event RemovePlayerFromLeaderboard(uint256 indexed leaderboardIndex, address player);

    function createLeaderboard(LeaderboardInfo calldata leaderboardInfo) external;

    function updateLeaderboardInfo(uint256 leaderboardIndex, LeaderboardInfo calldata leaderboardInfo) external;

    function addPlayerToLeaderboard(uint256 leaderboardIndex, address player) external;

    function removePlayerFromLeaderboard(uint256 leaderboardIndex, address player) external;

    function createLeaderboardWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function updateLeaderboardInfoWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature)
        external;

    function addPlayerToLeaderboardWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature)
        external;

    function removePlayerFromLeaderboardWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature)
        external;

    function getLeaderboardCount() external view returns (uint256 leaderboardCount);

    function getLeaderboardInfo(uint256 leaderboardIndex)
        external
        view
        returns (LeaderboardInfo memory leaderboardInfo);

    function getPlayerScore(uint256 leaderboardIndex, address player) external view returns (uint256 score);

    function getPlayerRank(uint256 leaderboardIndex, address player) external view returns (uint256 rank);

    function getLeaderboardScores(uint256 leaderboardIndex, SortOrder sortOrder)
        external
        view
        returns (LeaderboardScore[] memory scores);

    function getLeaderboardScoresInRange(
        uint256 leaderboardIndex,
        uint256 start,
        uint256 end,
        SortOrder sortOrder
    ) external view returns (LeaderboardScore[] memory scores);
}
