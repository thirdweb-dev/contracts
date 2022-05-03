// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IPermissions.sol";
import "./Context.sol";
import "../lib/Strings.sol";

contract Permissions is IPermissions, Context {
    
    mapping(bytes32 => mapping(address => bool)) public hasRole;
    mapping(bytes32 => bytes32) public getRoleAdmin;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function grantRole(bytes32 role, address account) external {
        require(
            hasRole[getRoleAdmin[role]][_msgSender()],
            "Not role admin."
        );

        hasRole[role][account] = true;

        emit RoleGranted(role, account, _msgSender());
    }

    function revokeRole(bytes32 role, address account) external {
        require(
            hasRole[getRoleAdmin[role]][_msgSender()],
            "Not role admin."
        );

        delete hasRole[role][account];

        emit RoleRevoked(role, account, _msgSender());
    }

    function renounceRole(bytes32 role, address account) external {
        require(
            _msgSender() == account,
            "Can only renounce for self"
        );

        delete hasRole[role][account];

        emit RoleRevoked(role, account, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole[role][account]) {
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