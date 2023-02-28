// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { PermissionsStorage } from "../extension/Permissions.sol";

contract PermissionsInit {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        data._hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }
}
