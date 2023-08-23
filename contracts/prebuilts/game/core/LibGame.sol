// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGame } from "./IGame.sol";

library LibGame {
    function gameStorage() internal pure returns (IGame.GameStorage storage numberData) {
        assembly {
            numberData.slot := 0
        }
    }
}

contract Modifiers {
    IGame.GameStorage internal gs;

    modifier onlyAdmin() {
        require(msg.sender == gs.admin, "Modifiers: Not admin.");
        _;
    }

    modifier onlyManagers() {
        require(gs.managers[msg.sender], "Modifiers: Not manager.");
        _;
    }

    modifier onlyPlayers() {
        require(gs.players[msg.sender], "Modifiers: Not player.");
        _;
    }
}
