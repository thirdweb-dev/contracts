// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGame } from "./IGame.sol";
import { BaseRouter } from "lib/dynamic-contracts/src/presets/BaseRouter.sol";
import { Modifiers } from "./LibGame.sol";

contract Game is IGame, BaseRouter, Modifiers {
    constructor(address admin) {
        gs.admin = admin;
        gs.managers[admin] = true;
    }

    function setAdmin(address admin) external onlyAdmin {
        require(admin != address(0), "GameRouter: Admin cannot be zero address.");
        gs.admin = admin;
    }

    function addManager(address manager) external onlyAdmin {
        gs.managers[manager] = true;
    }

    function removeManager(address manager) external onlyAdmin {
        gs.managers[manager] = false;
    }

    function addPlayer(address player) external onlyManagers {
        gs.players[player] = true;
    }

    function removePlayer(address player) external onlyManagers {
        gs.players[player] = false;
    }

    function isAdmin(address admin) external view returns (bool) {
        return gs.admin == admin;
    }

    function isManager(address manager) external view returns (bool) {
        return gs.managers[manager];
    }

    function isPlayer(address player) external view returns (bool) {
        return gs.players[player];
    }

    function _canSetExtension(Extension memory) internal view virtual override returns (bool) {
        return msg.sender == gs.admin;
    }
}
