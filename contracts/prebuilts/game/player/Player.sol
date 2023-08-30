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

import { IPlayer } from "./IPlayer.sol";
import { GameLibrary } from "../core/LibGame.sol";
import { PlayerStorage } from "./PlayerStorage.sol";

contract Player is IPlayer, GameLibrary {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a player and set player info.
    function createPlayer(address player, PlayerInfo calldata playerInfo) external onlyManager {
        _createPlayer(player, playerInfo);
    }

    /// @dev Update player info.
    function updatePlayerInfo(address player, PlayerInfo calldata playerInfo) external onlyManager {
        _updatePlayerInfo(player, playerInfo);
    }

    /*///////////////////////////////////////////////////////////////
                        Signature-based external functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a player and set player info with signature.
    function createPlayerWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (address player, PlayerInfo memory playerInfo) = abi.decode(req.data, (address, PlayerInfo));
        _createPlayer(player, playerInfo);
    }

    /// @dev Update player info with signature.
    function updatePlayerInfoWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (address player, PlayerInfo memory playerInfo) = abi.decode(req.data, (address, PlayerInfo));
        _updatePlayerInfo(player, playerInfo);
    }

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Get player info.
    function getPlayerInfo(address player) public view returns (PlayerInfo memory playerInfo) {
        return PlayerStorage.playerStorage().playerInfo[player];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a player and set player info.
    function _createPlayer(address player, PlayerInfo memory playerInfo) internal {
        require(!gs.players[player], "Player: Player already exists.");
        gs.players[player] = true;
        _updatePlayerInfo(player, playerInfo);
        emit CreatePlayer(player, playerInfo);
    }

    /// @dev Update player info.
    function _updatePlayerInfo(address player, PlayerInfo memory playerInfo) internal {
        require(gs.players[player], "Player: Player does not exist.");
        PlayerStorage.playerStorage().playerInfo[player] = playerInfo;
        emit UpdatePlayerInfo(player, playerInfo);
    }
}
