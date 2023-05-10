// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/IPermissionsSig.sol";
import "../../lib/TWStrings.sol";
import "../../openzeppelin-presets/utils/cryptography/EIP712.sol";

/**
 *  @title   Permissions
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms
 */

library PermissionsSigStorage {
    bytes32 public constant PERMISSIONS_STORAGE_POSITION = keccak256("permissions.sig.storage");

    struct Data {
        /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
        mapping(bytes32 => mapping(address => bool)) _hasRole;
        /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
        mapping(bytes32 => bytes32) _getRoleAdmin;
        /// @dev Mapping from a signed request UID => whether the request is processed.
        mapping(bytes32 => bool) executed;
    }

    function permissionsSigStorage() internal pure returns (Data storage permissionsData) {
        bytes32 position = PERMISSIONS_STORAGE_POSITION;
        assembly {
            permissionsData.slot := position
        }
    }
}

abstract contract PermissionsSigUtils is IPermissionsSig, EIP712 {
    using ECDSA for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256(
            "RoleRequest(bytes32 role,address target,uint8 action,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Verifies that a request is signed by an authorized account.
    function verifyRoleRequest(RoleRequest calldata req, bytes calldata signature)
        public
        view
        virtual
        returns (bool success, address signer)
    {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        signer = _recoverAddress(req, signature);
        success = !data.executed[req.uid] && _isAuthorizedSigner(signer, req, data);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Verifies a request and marks the request as processed.
    function _processRoleRequest(RoleRequest calldata _req, bytes calldata _signature)
        internal
        virtual
        returns (address signer)
    {
        bool success;
        (success, signer) = verifyRoleRequest(_req, _signature);

        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();

        if (!success) {
            revert("Invalid req");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("Req expired");
        }

        data.executed[_req.uid] = true;
    }

    /// @dev Returns the address of the signer of the request.
    function _recoverAddress(RoleRequest calldata _req, bytes calldata _signature)
        internal
        view
        virtual
        returns (address)
    {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Encodes a request for recovery of the signer in `recoverAddress`.
    function _encodeRequest(RoleRequest calldata _req) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.role,
                _req.target,
                _req.action,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid
            );
    }

    /// @dev Returns whether a given address is authorized to sign requests.
    function _isAuthorizedSigner(
        address signer,
        RoleRequest calldata req,
        PermissionsSigStorage.Data storage data
    ) internal view virtual returns (bool) {}
}

abstract contract PermissionsSig is PermissionsSigUtils {
    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Modifier that checks if an account has the specified role; reverts otherwise.
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Checks whether an account has a particular role.
     *  @dev            Returns `true` if `account` has been granted `role`.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        return data._hasRole[role][account];
    }

    /**
     *  @notice         Checks whether an account has a particular role;
     *                  role restrictions can be swtiched on and off.
     *
     *  @dev            Returns `true` if `account` has been granted `role`.
     *                  Role restrictions can be swtiched on and off:
     *                      - If address(0) has ROLE, then the ROLE restrictions
     *                        don't apply.
     *                      - If address(0) does not have ROLE, then the ROLE
     *                        restrictions will apply.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(bytes32 role, address account) public view returns (bool) {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        if (!data._hasRole[role][address(0)]) {
            return data._hasRole[role][account];
        }

        return true;
    }

    /**
     *  @notice         Returns the admin role that controls the specified role.
     *  @dev            See {grantRole} and {revokeRole}.
     *                  To change a role's admin, use {_setRoleAdmin}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(bytes32 role) external view override returns (bytes32) {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        return data._getRoleAdmin[role];
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Grants a role to an account, if not previously granted.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleGranted Event}.
     *
     *  @param req     The request body to grant a role to an account.
     *  @param signature  Signature of a party authorized to grant role.
     */
    function grantRole(RoleRequest calldata req, bytes calldata signature) public virtual override {
        require(req.action == RoleAction.Grant, "Invalid action");
        _processRoleRequest(req, signature);
        _setupRole(req.role, req.target);
    }

    /**
     *  @notice         Revokes role from an account.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param req     The request body to revoke a role from an account.
     *  @param signature  Signature of a party authorized to revoke role.
     */
    function revokeRole(RoleRequest calldata req, bytes calldata signature) public virtual override {
        require(req.action == RoleAction.Revoke, "Invalid action");
        _processRoleRequest(req, signature);
        _revokeRole(req.role, req.target);
    }

    /**
     *  @notice         Revokes role from the account.
     *  @dev            Caller must have the `role`, with caller being the same as `account`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param req     The request body to renounce a role.
     *  @param signature  Signature of a party authorized to renounce role.
     */
    function renounceRole(RoleRequest calldata req, bytes calldata signature) public virtual override {
        require(req.action == RoleAction.Renounce, "Invalid action");
        _processRoleRequest(req, signature);
        _revokeRole(req.role, req.target);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        bytes32 previousAdminRole = data._getRoleAdmin[role];
        data._getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        if (data._hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        data._hasRole[role][account] = true;
        emit RoleGranted(role, account, _msgSender());
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal virtual {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        _checkRole(role, account);
        delete data._hasRole[role][account];
        emit RoleRevoked(role, account, _msgSender());
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view virtual {
        PermissionsSigStorage.Data storage data = PermissionsSigStorage.permissionsSigStorage();
        if (!data._hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(bytes32 role, address account) internal view virtual {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Returns whether a given address is authorized to sign requests.
    function _isAuthorizedSigner(
        address signer,
        RoleRequest calldata req,
        PermissionsSigStorage.Data storage data
    ) internal view virtual override returns (bool) {
        if (req.action == RoleAction.Renounce) {
            require(signer == req.target, "Can only renounce for self");
        } else {
            _checkRole(data._getRoleAdmin[req.role], signer);
        }
        return true;
    }

    function _msgSender() internal view virtual returns (address sender) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
