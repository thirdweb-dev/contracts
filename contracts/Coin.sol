// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// Token + Access Control
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Coin is ERC20PresetMinterPauser {
    constructor(
        string memory _name,
        string memory _symbol,
        address _defaultAdmin
    ) ERC20PresetMinterPauser(_name, _symbol) {
        // Renounce roles for deployer
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        renounceRole(MINTER_ROLE, _msgSender());
        renounceRole(PAUSER_ROLE, _msgSender());

        // Grant DEFAULT_ADMIN_ROLE to intended admin
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
    }
}
