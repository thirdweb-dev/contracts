// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPlayer } from "./IPlayer.sol";

library PlayerStorage {
    bytes32 public constant PLAYER_STORAGE_POSITION = keccak256("player.storage");

    struct Data {
        mapping(address => IPlayer.PlayerInfo) playerInfo;
    }

    function playerStorage() internal pure returns (Data storage playerData) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            playerData.slot := position
        }
    }
}
