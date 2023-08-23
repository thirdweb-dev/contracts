// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlayer {
    struct PlayerInfo {
        string name;
    }

    function setAdmin(address admin) external;

    function addManager(address manager) external;

    function removeManager(address manager) external;

    function addPlayer(address player) external;

    function removePlayer(address player) external;
}
