// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MockERC20CustomDecimals is ERC20PresetMinterPauser, ERC20Permit {
    uint8 private immutable _decimals;

    constructor(uint8 decimals_) ERC20PresetMinterPauser("Mock Coin", "MOCK") ERC20Permit("Mock Coin") {
        _decimals = decimals_;
    }

    function mint(address to, uint256 amount) public override(ERC20PresetMinterPauser) {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20PresetMinterPauser, ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
