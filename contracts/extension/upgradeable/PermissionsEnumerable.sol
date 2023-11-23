// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPermissionsEnumerable.sol";
import "./Permissions.sol";

/**
 *  @title   PermissionsEnumerable
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms.
 *           Also provides interfaces to view all members with a given role, and total count of members.
 */

library PermissionsEnumerableStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant PERMISSIONS_ENUMERABLE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("permissions.enumerable.storage")) - 1)) & ~bytes32(uint256(0xff));

    /**
     *  @notice A data structure to store data of members for a given role.
     *
     *  @param index    Current index in the list of accounts that have a role.
     *  @param members  map from index => address of account that has a role
     *  @param indexOf  map from address => index which the account has.
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    struct Data {
        /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
        mapping(bytes32 => RoleMembers) roleMembers;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = PERMISSIONS_ENUMERABLE_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

contract PermissionsEnumerable is IPermissionsEnumerable, Permissions {
    /**
     *  @notice         Returns the role-member from a list of members for a role,
     *                  at a given index.
     *  @dev            Returns `member` who has `role`, at `index` of role-members list.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index    Index in list of current members for the role.
     *
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address member) {
        uint256 currentIndex = _permissionsEnumerableStorage().roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (_permissionsEnumerableStorage().roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = _permissionsEnumerableStorage().roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (
                hasRole(role, address(0)) && i == _permissionsEnumerableStorage().roleMembers[role].indexOf[address(0)]
            ) {
                check += 1;
            }
        }
    }

    /**
     *  @notice         Returns total number of accounts that have a role.
     *  @dev            Returns `count` of accounts that have `role`.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *
     *  @return count   Total number of accounts that have `role`
     */
    function getRoleMemberCount(bytes32 role) external view override returns (uint256 count) {
        uint256 currentIndex = _permissionsEnumerableStorage().roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (_permissionsEnumerableStorage().roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
        if (hasRole(role, address(0))) {
            count += 1;
        }
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    ///      See {_removeMember}
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        uint256 idx = _permissionsEnumerableStorage().roleMembers[role].index;
        _permissionsEnumerableStorage().roleMembers[role].index += 1;

        _permissionsEnumerableStorage().roleMembers[role].members[idx] = account;
        _permissionsEnumerableStorage().roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        uint256 idx = _permissionsEnumerableStorage().roleMembers[role].indexOf[account];

        delete _permissionsEnumerableStorage().roleMembers[role].members[idx];
        delete _permissionsEnumerableStorage().roleMembers[role].indexOf[account];
    }

    /// @dev Returns the PermissionsEnumerable storage.
    function _permissionsEnumerableStorage() internal pure returns (PermissionsEnumerableStorage.Data storage data) {
        data = PermissionsEnumerableStorage.data();
    }
}
