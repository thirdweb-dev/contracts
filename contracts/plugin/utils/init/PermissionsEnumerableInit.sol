// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { PermissionsEnumerableStorage } from "../PermissionsEnumerable.sol";
import { PermissionsInit } from "./PermissionsInit.sol";

contract PermissionsEnumerableInit is PermissionsInit {
    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.permissionsEnumerableStorage();
        uint256 idx = data.roleMembers[role].index;
        data.roleMembers[role].index += 1;

        data.roleMembers[role].members[idx] = account;
        data.roleMembers[role].indexOf[account] = idx;
    }
}
