// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGame } from "./IGame.sol";
import { GameSignature } from "../utils/GameSignature.sol";

library LibGame {
    function gameStorage() internal pure returns (IGame.GameStorage storage numberData) {
        assembly {
            numberData.slot := 0
        }
    }
}

contract GameLibrary is GameSignature {
    IGame.GameStorage internal gs;

    modifier onlyAdmin() {
        require(msg.sender == gs.admin, "GameLibrary: Not admin.");
        _;
    }

    modifier onlyManager() {
        require(gs.managers[msg.sender], "GameLibrary: Not manager.");
        _;
    }

    modifier onlyPlayer() {
        require(gs.players[msg.sender], "GameLibrary: Not player.");
        _;
    }

    modifier onlyManagerApproved(GameRequest calldata req, bytes calldata signature) {
        address signer = _processRequest(req, signature);
        require(gs.managers[signer], "GameLibrary: Not manager approved.");
        _;
    }

    function _isAuthorizedSigner(address _signer) internal view virtual override returns (bool) {
        return gs.managers[_signer];
    }
}
