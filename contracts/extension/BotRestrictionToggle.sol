// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./interface/IBotRestrictionToggle.sol";

abstract contract BotRestrictionToggle is IBotRestrictionToggle {
    /// @dev Restrict automated actions via smart contracts.
    bool public botRestriction;

    function setBotRestriction(bool _restriction) external {
        require(_canSetBotRestriction(), "Not authorized to set bot restriction.");
        _setBotRestriction(_restriction);
    }

    function _setBotRestriction(bool _restriction) internal {
        botRestriction = _restriction;
        emit BotRestriction(_restriction);
    }

    /// @dev Check if the tx is from EOA.
    function _botCheck() internal view virtual returns (bool);

    function _canSetBotRestriction() internal virtual returns (bool);
}
