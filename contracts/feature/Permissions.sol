// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IPermissions.sol";
import "../lib/Strings.sol";

contract Permissions is IPermissions {
    mapping(bytes32 => mapping(address => bool)) private _hasRole;
    mapping(bytes32 => bytes32) private _getRoleAdmin;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _hasRole[role][account];
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _getRoleAdmin[role];
    }

    function grantRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);

        _hasRole[role][account] = true;

        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);

        delete _hasRole[role][account];

        emit RoleRevoked(role, account, msg.sender);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(msg.sender == account, "Can only renounce for self");

        delete _hasRole[role][account];

        emit RoleRevoked(role, account, msg.sender);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin[role];
        _getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
}
