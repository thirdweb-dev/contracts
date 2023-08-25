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

import { IGame } from "./IGame.sol";
import { GameLibrary } from "./LibGame.sol";

//  ==========  External imports    ==========

import { BaseRouter } from "lib/dynamic-contracts/src/presets/BaseRouter.sol";

contract Game is IGame, GameLibrary, BaseRouter {
    /*///////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets admin and automatically adds them as a manager.
    constructor(address admin, GameMetadata memory metadata) {
        gs.admin = admin;
        gs.managers[admin] = true;
        gs.metadata = metadata;
        emit GameInitialized(msg.sender, admin, metadata);
    }

    /*///////////////////////////////////////////////////////////////
                        Admin functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets new admin.
    function setAdmin(address admin) external onlyAdmin {
        require(gs.admin != admin, "GameRouter: AlreadyAdmin.");
        gs.admin = admin;
        emit SetAdmin(admin);
    }

    /// @dev Adds a manager.
    function addManager(address manager) external onlyAdmin {
        require(gs.managers[manager], "GameRouter: Manager already exists.");
        gs.managers[manager] = true;
        emit AddManager(manager);
    }

    /// @dev Removes a manager.
    function removeManager(address manager) external onlyAdmin {
        require(!gs.managers[manager], "GameRouter: Manager does not exist.");
        gs.managers[manager] = false;
        emit RemoveManager(manager);
    }

    /// @dev Updates game metadata.
    function updateMetadata(GameMetadata memory metadata) external onlyAdmin {
        gs.metadata = metadata;
        emit UpdateMetadata(metadata);
    }

    /*///////////////////////////////////////////////////////////////
                        Manager functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a player.
    function addPlayer(address player) external onlyManager {
        require(gs.players[player], "GameRouter: Player already exists.");
        gs.players[player] = true;
        emit AddPlayer(player);
    }

    /// @dev Removes a player.
    function removePlayer(address player) external onlyManager {
        require(!gs.players[player], "GameRouter: Player does not exist.");
        gs.players[player] = false;
        emit RemovePlayer(player);
    }

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether address is admin.
    function isAdmin(address admin) public view returns (bool) {
        return gs.admin == admin;
    }

    /// @dev Returns whether address is manager.
    function isManager(address manager) public view returns (bool) {
        return gs.managers[manager];
    }

    /// @dev Returns whether address is player.
    function isPlayer(address player) public view returns (bool) {
        return gs.players[player];
    }

    /// @dev Returns game metadata.
    function getMetadata() public view returns (GameMetadata memory) {
        return gs.metadata;
    }

    /*///////////////////////////////////////////////////////////////
                        BaseRouter overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether address can set extension(s).
    function _canSetExtension(Extension memory) internal view virtual override returns (bool) {
        return msg.sender == gs.admin;
    }
}
