// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGame {
    struct GameMetadata {
        string name;
        string description;
        string website;
        string logo;
    }

    struct GameStorage {
        address admin;
        mapping(address => bool) managers;
        mapping(address => bool) players;
        GameMetadata metadata;
    }

    event GameInitialized(address indexed deployer, address indexed admin, GameMetadata metadata);
    event SetAdmin(address indexed admin);
    event AddManager(address indexed manager);
    event RemoveManager(address indexed manager);
    event AddPlayer(address indexed player);
    event RemovePlayer(address indexed player);
    event UpdateMetadata(GameMetadata metadata);

    function setAdmin(address admin) external;

    function addManager(address manager) external;

    function removeManager(address manager) external;

    function addPlayer(address player) external;

    function removePlayer(address player) external;
}
