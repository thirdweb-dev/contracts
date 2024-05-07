// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MockERC20 is ERC20PresetMinterPauser, ERC20Permit {
    bool internal taxActive;

    constructor() ERC20PresetMinterPauser("Mock Coin", "MOCK") ERC20Permit("Mock Coin") {}

    function mint(address to, uint256 amount) public override(ERC20PresetMinterPauser) {
        _mint(to, amount);
    }

    function toggleTax() external {
        taxActive = !taxActive;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (taxActive) {
            uint256 tax = (amount * 10) / 100;
            amount -= tax;
            super._transfer(from, address(this), tax);
        }
        super._transfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20PresetMinterPauser, ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
