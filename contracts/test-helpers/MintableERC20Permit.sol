// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Token + Access Control
import "../openzeppelin-presets/ERC20PresetMinterPauser.sol";

contract MintableERC20Permit is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("USD Coin", "USDC") {}

    /// @dev Ignore MINTER_ROLE
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return role == MINTER_ROLE || super.hasRole(role, account);
    }
}
