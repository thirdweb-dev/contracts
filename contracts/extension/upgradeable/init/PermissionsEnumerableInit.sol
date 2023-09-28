// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { PermissionsEnumerableStorage } from "../PermissionsEnumerable.sol";
import "./PermissionsInit.sol";

contract PermissionsEnumerableInit is PermissionsInit {
    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        PermissionsEnumerableStorage.Data storage data = PermissionsEnumerableStorage.data();
        uint256 idx = data.roleMembers[role].index;
        data.roleMembers[role].index += 1;

        data.roleMembers[role].members[idx] = account;
        data.roleMembers[role].indexOf[account] = idx;
    }
}
