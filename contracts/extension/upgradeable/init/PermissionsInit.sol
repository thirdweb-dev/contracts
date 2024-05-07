// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { PermissionsStorage } from "../Permissions.sol";

contract PermissionsInit {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        data._hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        bytes32 previousAdminRole = data._getRoleAdmin[role];
        data._getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
}
