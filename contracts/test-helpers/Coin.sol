// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Coin is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("ExampleCoin", "COIN") {}
}
