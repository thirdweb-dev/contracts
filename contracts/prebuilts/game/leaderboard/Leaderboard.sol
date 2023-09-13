// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  Internal imports    ==========

import { ILeaderboard } from "./ILeaderboard.sol";
import { GameLibrary } from "../core/LibGame.sol";
import { LeaderboardStorage } from "./LeaderboardStorage.sol";
import { RulesEngine } from "../../../../contracts/extension/upgradeable/RulesEngine.sol";

contract Leaderboard is ILeaderboard, GameLibrary, RulesEngine {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a leaderboard and set leaderboard info.
    function createLeaderboard(LeaderboardInfo calldata leaderboardInfo) external onlyManager {
        _createLeaderboard(leaderboardInfo);
    }

    /// @dev Update leaderboard info.
    function updateLeaderboardInfo(uint256 leaderboardIndex, LeaderboardInfo calldata leaderboardInfo)
        external
        onlyManager
    {
        _updateLeaderboardInfo(leaderboardIndex, leaderboardInfo);
    }

    /// @dev Add player to leaderboard.
    function addPlayerToLeaderboard(uint256 leaderboardIndex, address player) external onlyManager {
        _addPlayerToLeaderboard(leaderboardIndex, player);
    }

    /// @dev Remove player from leaderboard.
    function removePlayerFromLeaderboard(uint256 leaderboardIndex, address player) external onlyManager {
        _removePlayerFromLeaderboard(leaderboardIndex, player);
    }

    /*///////////////////////////////////////////////////////////////
                        Signature-based external functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a leaderboard and set leaderboard info with signature.
    function createLeaderboardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        LeaderboardInfo memory leaderboardInfo = abi.decode(req.data, (LeaderboardInfo));
        _createLeaderboard(leaderboardInfo);
    }

    /// @dev Update leaderboard info with signature.
    function updateLeaderboardInfoWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (uint256 leaderboardIndex, LeaderboardInfo memory leaderboardInfo) = abi.decode(
            req.data,
            (uint256, LeaderboardInfo)
        );
        _updateLeaderboardInfo(leaderboardIndex, leaderboardInfo);
    }

    /// @dev Add player to leaderboard with signature.
    function addPlayerToLeaderboardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (uint256 leaderboardIndex, address player) = abi.decode(req.data, (uint256, address));
        _addPlayerToLeaderboard(leaderboardIndex, player);
    }

    /// @dev Remove player from leaderboard with signature.
    function removePlayerFromLeaderboardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (uint256 leaderboardIndex, address player) = abi.decode(req.data, (uint256, address));
        _removePlayerFromLeaderboard(leaderboardIndex, player);
    }

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Get leaderboard count.
    function getLeaderboardCount() public view returns (uint256 leaderboardCount) {
        return LeaderboardStorage.leaderboardStorage().leaderboardCount;
    }

    /// @dev Get leaderboard info.
    function getLeaderboardInfo(uint256 leaderboardIndex) public view returns (LeaderboardInfo memory leaderboardInfo) {
        return LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboardIndex];
    }

    /// @dev Get score for a player.
    function getPlayerScore(uint256 leaderboardIndex, address player) public view returns (uint256 score) {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[
            leaderboardIndex
        ];
        return getScoreForRules(player, leaderboardInfo.rules);
    }

    /// @dev Get player rank for a leaderboard.
    function getPlayerRank(uint256 leaderboardIndex, address player) public view returns (uint256 rank) {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[
            leaderboardIndex
        ];
        uint256 len = leaderboardInfo.players.length;
        uint256 playerScore = getScoreForRules(player, leaderboardInfo.rules);
        LeaderboardScore[] memory scores = getLeaderboardScores(leaderboardIndex, SortOrder.None);
        rank = scores.length;
        for (uint256 i = 0; i < len; i += 1) {
            if (playerScore > scores[i].score) {
                rank -= 1;
            }
        }
    }

    // @dev Get all scores for a leaderboard with optional sorting.
    function getLeaderboardScores(uint256 leaderboardIndex, SortOrder sortOrder)
        public
        view
        returns (LeaderboardScore[] memory scores)
    {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[
            leaderboardIndex
        ];
        uint256 len = leaderboardInfo.players.length;
        scores = new LeaderboardScore[](len);

        for (uint256 i = 0; i < len; i += 1) {
            scores[i] = LeaderboardScore({
                player: leaderboardInfo.players[i],
                score: getScoreForRules(leaderboardInfo.players[i], leaderboardInfo.rules)
            });
        }

        if (sortOrder == SortOrder.Ascending) {
            _sortAscending(scores);
        } else if (sortOrder == SortOrder.Descending) {
            _sortDescending(scores);
        }
    }

    /// @dev Get all scores for a leaderboard within an unsorted range with optional sorting at the end.
    function getLeaderboardScoresInRange(
        uint256 leaderboardIndex,
        uint256 start,
        uint256 end,
        SortOrder sortOrder
    ) public view returns (LeaderboardScore[] memory scores) {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[
            leaderboardIndex
        ];
        uint256 len = end - start;
        scores = new LeaderboardScore[](len);

        for (uint256 i = 0; i < len; i++) {
            scores[i] = LeaderboardScore({
                player: leaderboardInfo.players[start + i],
                score: getScoreForRules(leaderboardInfo.players[start + i], leaderboardInfo.rules)
            });
        }

        if (sortOrder == SortOrder.Ascending) {
            _sortAscending(scores);
        } else if (sortOrder == SortOrder.Descending) {
            _sortDescending(scores);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a leaderboard and set leaderboard info.
    function _createLeaderboard(LeaderboardInfo memory leaderboardInfo) internal {
        LeaderboardStorage.Data storage leaderboardData = LeaderboardStorage.leaderboardStorage();
        uint256 leaderboardIndex = leaderboardData.leaderboardCount;
        ++leaderboardData.leaderboardCount;
        _updateLeaderboardInfo(leaderboardIndex, leaderboardInfo);
        emit CreateLeaderboard(leaderboardIndex, leaderboardInfo);
    }

    /// @dev Update leaderboard info.
    function _updateLeaderboardInfo(uint256 leaderboardIndex, LeaderboardInfo memory leaderboardInfo) internal {
        LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboardIndex] = leaderboardInfo;
        emit UpdateLeaderboardInfo(leaderboardIndex, leaderboardInfo);
    }

    /// @dev Add player to leaderboard.
    function _addPlayerToLeaderboard(uint256 leaderboardIndex, address player) internal {
        LeaderboardInfo storage leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[
            leaderboardIndex
        ];
        leaderboardInfo.players.push(player);
        emit AddPlayerToLeaderboard(leaderboardIndex, player);
    }

    /// @dev Remove player from leaderboard.
    function _removePlayerFromLeaderboard(uint256 leaderboardIndex, address player) internal {
        LeaderboardInfo storage leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[
            leaderboardIndex
        ];
        uint256 len = leaderboardInfo.players.length;
        for (uint256 i = 0; i < len; i += 1) {
            if (leaderboardInfo.players[i] == player) {
                leaderboardInfo.players[i] = leaderboardInfo.players[len - 1];
                leaderboardInfo.players.pop();
                break;
            }
        }
        emit RemovePlayerFromLeaderboard(leaderboardIndex, player);
    }

    /// @dev Sort leaderboard scores in ascending order.
    function _sortAscending(LeaderboardScore[] memory arr) internal pure {
        uint256 len = arr.length;
        for (uint256 i = 0; i < len - 1; i++) {
            for (uint256 j = 0; j < len - i - 1; j++) {
                if (arr[j].score > arr[j + 1].score) {
                    LeaderboardScore memory temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
    }

    /// @dev Sort leaderboard scores in descending order.
    function _sortDescending(LeaderboardScore[] memory arr) internal pure {
        uint256 len = arr.length;
        for (uint256 i = 0; i < len - 1; i++) {
            for (uint256 j = 0; j < len - i - 1; j++) {
                if (arr[j].score < arr[j + 1].score) {
                    LeaderboardScore memory temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        RulesEngine Overrides
    //////////////////////////////////////////////////////////////*/

    function getScore(address) public pure override returns (uint256) {
        revert("Leaderboard: use getPlayerScore instead.");
    }

    function _canSetRules() internal view override returns (bool) {
        return gs.managers[msg.sender];
    }

    function _canOverrideRulesEngine() internal view override returns (bool) {
        return gs.admin == msg.sender;
    }
}
