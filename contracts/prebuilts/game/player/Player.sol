// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPlayer } from "./IPlayer.sol";
import { Modifiers } from "../core/LibGame.sol";
import { PlayerStorage } from "./PlayerStorage.sol";

contract Player is Modifiers {
    function createPlayer(address player, IPlayer.PlayerInfo calldata playerInfo) external onlyManagers {
        if (gs.players[player]) revert("Player: Player already exists.");
        gs.players[player] = true;
        PlayerStorage.playerStorage().playerInfo[player] = playerInfo;
    }

    function updatePlayerInfo(address player, IPlayer.PlayerInfo calldata playerInfo) external onlyManagers {
        if (!gs.players[player]) revert("Player: Player does not exist.");
        PlayerStorage.playerStorage().playerInfo[player] = playerInfo;
    }

    function getPlayerInfo(address player) external view returns (IPlayer.PlayerInfo memory) {
        return PlayerStorage.playerStorage().playerInfo[player];
    }
}
