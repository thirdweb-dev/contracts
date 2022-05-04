// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IPermissionsEnumerable.sol";
import "./Permissions.sol";

contract PermissionsEnumerable is IPermissionsEnumerable, Permissions {
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    mapping(bytes32 => RoleMembers) private roleMembers;

    function getRoleMember(bytes32 role, uint256 index) external view override returns (address member) {
        uint256 currentIndex = roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = roleMembers[role].members[i];
                }
            } else {
                check += 1;
            }
        }
    }

    function getRoleMemberCount(bytes32 role) external view override returns (uint256 count) {
        uint256 currentIndex = roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
    }

    function grantRole(bytes32 role, address account) public override(IPermissions, Permissions) {
        super.grantRole(role, account);
        _addMember(role, account);
    }

    function revokeRole(bytes32 role, address account) public override(IPermissions, Permissions) {
        super.revokeRole(role, account);
        _removeMember(role, account);
    }

    function renounceRole(bytes32 role, address account) public override(IPermissions, Permissions) {
        super.renounceRole(role, account);
        _removeMember(role, account);
    }

    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    function _addMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].index;
        roleMembers[role].index += 1;

        roleMembers[role].members[idx] = account;
        roleMembers[role].indexOf[account] = idx;
    }

    function _removeMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].indexOf[account];

        delete roleMembers[role].members[idx];
        delete roleMembers[role].indexOf[account];
    }
}
