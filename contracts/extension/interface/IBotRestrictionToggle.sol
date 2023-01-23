// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

interface IBotRestrictionToggle {
    event BotRestriction(bool restriction);

    function botRestriction() external view returns (bool);

    function setBotRestriction(bool restriction) external;
}
