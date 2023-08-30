// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGameSignature } from "../utils/IGameSignature.sol";

interface IPlayer {
    struct PlayerInfo {
        string name;
        string avatar;
        uint256 level;
        bytes data;
    }

    event CreatePlayer(address indexed player, PlayerInfo playerInfo);
    event UpdatePlayerInfo(address indexed player, PlayerInfo playerInfo);

    function createPlayer(address player, PlayerInfo calldata playerInfo) external;

    function updatePlayerInfo(address player, PlayerInfo calldata playerInfo) external;

    function createPlayerWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function updatePlayerInfoWithSignature(IGameSignature.GameRequest calldata req, bytes calldata signature) external;

    function getPlayerInfo(address player) external view returns (PlayerInfo memory playerInfo);
}
