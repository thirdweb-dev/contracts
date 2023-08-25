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
    function createLeaderboard(uint256 leaderboard, LeaderboardInfo calldata leaderboardInfo) external onlyManager {
        _createLeaderboard(leaderboard, leaderboardInfo);
    }

    /// @dev Update leaderboard info.
    function updateLeaderboardInfo(uint256 leaderboard, LeaderboardInfo calldata leaderboardInfo) external onlyManager {
        _updateLeaderboardInfo(leaderboard, leaderboardInfo);
    }

    /// @dev Add player to leaderboard.
    function addPlayerToLeaderboard(uint256 leaderboard, address player) external onlyManager {
        _addPlayerToLeaderboard(leaderboard, player);
    }

    /// @dev Remove player from leaderboard.
    function removePlayerFromLeaderboard(uint256 leaderboard, address player) external onlyManager {
        _removePlayerFromLeaderboard(leaderboard, player);
    }

    /*///////////////////////////////////////////////////////////////
                        Signature-based external functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a leaderboard and set leaderboard info with signature.
    function createLeaderboardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (uint256 leaderboard, LeaderboardInfo memory leaderboardInfo) = abi.decode(
            req.data,
            (uint256, LeaderboardInfo)
        );
        _createLeaderboard(leaderboard, leaderboardInfo);
    }

    /// @dev Update leaderboard info with signature.
    function updateLeaderboardInfoWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (uint256 leaderboard, LeaderboardInfo memory leaderboardInfo) = abi.decode(
            req.data,
            (uint256, LeaderboardInfo)
        );
        _updateLeaderboardInfo(leaderboard, leaderboardInfo);
    }

    /// @dev Add player to leaderboard with signature.
    function addPlayerToLeaderboardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (uint256 leaderboard, address player) = abi.decode(req.data, (uint256, address));
        _addPlayerToLeaderboard(leaderboard, player);
    }

    /// @dev Remove player from leaderboard with signature.
    function removePlayerFromLeaderboardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (uint256 leaderboard, address player) = abi.decode(req.data, (uint256, address));
        _removePlayerFromLeaderboard(leaderboard, player);
    }

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Get leaderboard info.
    function getLeaderboardInfo(uint256 leaderboard) public view returns (LeaderboardInfo memory) {
        return LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard];
    }

    /// @dev Get score for a player.
    function getPlayerScore(uint256 leaderboard, address player) public view returns (uint256 score) {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard];
        return getScoreForRules(player, leaderboardInfo.rules);
    }

    /// @dev Get player rank for a leaderboard. Should be used from the frontend.
    function getPlayerRank(uint256 leaderboard, address player) public view returns (uint256 rank) {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard];
        uint256 len = leaderboardInfo.players.length;
        uint256 playerScore = getScoreForRules(player, leaderboardInfo.rules);
        LeaderboardScore[] memory scores = getLeaderboardScores(leaderboard);
        for (uint256 i = 0; i < len; i += 1) {
            if (playerScore > scores[i].score) {
                rank += 1;
            }
        }
        return rank;
    }

    /// @dev Get all scores for a leaderboard. Should be used from the frontend.
    function getLeaderboardScores(uint256 leaderboard) public view returns (LeaderboardScore[] memory scores) {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard];
        uint256 len = leaderboardInfo.players.length;
        scores = new LeaderboardScore[](len);
        for (uint256 i = 0; i < len; i += 1) {
            scores[i] = LeaderboardScore({
                player: leaderboardInfo.players[i],
                score: getScoreForRules(leaderboardInfo.players[i], leaderboardInfo.rules)
            });
        }
    }

    /// @dev Get all scores for a leaderboard within a range. Should be used from the frontend.
    function getLeaderboardScoresInRange(
        uint256 leaderboard,
        uint256 start,
        uint256 end
    ) public view returns (LeaderboardScore[] memory scores) {
        LeaderboardInfo memory leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard];
        scores = new LeaderboardScore[](end - start);
        for (uint256 i = start; i < end; i += 1) {
            scores[i] = LeaderboardScore({
                player: leaderboardInfo.players[i],
                score: getScoreForRules(leaderboardInfo.players[i], leaderboardInfo.rules)
            });
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a leaderboard and set leaderboard info.
    function _createLeaderboard(uint256 leaderboard, LeaderboardInfo memory leaderboardInfo) internal {
        _updateLeaderboardInfo(leaderboard, leaderboardInfo);
        emit CreateLeaderboard(leaderboard, leaderboardInfo);
    }

    /// @dev Update leaderboard info.
    function _updateLeaderboardInfo(uint256 leaderboard, LeaderboardInfo memory leaderboardInfo) internal {
        LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard] = leaderboardInfo;
        emit UpdateLeaderboardInfo(leaderboard, leaderboardInfo);
    }

    /// @dev Add player to leaderboard.
    function _addPlayerToLeaderboard(uint256 leaderboard, address player) internal {
        LeaderboardInfo storage leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard];
        leaderboardInfo.players.push(player);
        emit AddPlayerToLeaderboard(leaderboard, player);
    }

    /// @dev Remove player from leaderboard.
    function _removePlayerFromLeaderboard(uint256 leaderboard, address player) internal {
        LeaderboardInfo storage leaderboardInfo = LeaderboardStorage.leaderboardStorage().leaderboardInfo[leaderboard];
        uint256 len = leaderboardInfo.players.length;
        for (uint256 i = 0; i < len; i += 1) {
            if (leaderboardInfo.players[i] == player) {
                leaderboardInfo.players[i] = leaderboardInfo.players[len - 1];
                leaderboardInfo.players.pop();
                break;
            }
        }
        emit RemovePlayerFromLeaderboard(leaderboard, player);
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

    function _canOverrieRulesEngine() internal view override returns (bool) {
        return gs.admin == msg.sender;
    }
}
