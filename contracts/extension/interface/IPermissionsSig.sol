// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IPermissionsSig {
    /// @notice Roles can be granted, revoked or renounced by an authorized party.
    enum RoleAction {
        Grant,
        Revoke,
        Renounce
    }

    /**
     *  @notice The payload that must be signed by an authorized wallet to grant / revoke / renounce a role.
     *
     *  @param role The role to grant / revoke / renounce.
     *  @param target The address that is granted / revoked / renouncing the role.
     *  @param action Whether to grant, revoke or renounce the role.
     *  @param validityStartTimestamp The UNIX timestamp at and after which a signature is valid.
     *  @param validityEndTimestamp The UNIX timestamp at and after which a signature is invalid/expired.
     *  @param uid A unique non-repeatable ID for the payload.
     */
    struct RoleRequest {
        bytes32 role;
        address target;
        RoleAction action;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        bytes32 uid;
    }

    /// @dev Verifies that a request is signed by an authorized account.
    function verifyRoleRequest(IPermissionsSig.RoleRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `req.role` to `req.target`.
     *
     * If `req.target` had not been already granted `req.role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the signer must have `req.role`'s admin role.
     */
    function grantRole(RoleRequest calldata req, bytes calldata signature) external;

    /**
     * @dev Revokes `req.role` from `req.target`.
     *
     * If `req.target` had been granted `req.role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the signer must have `req.role`'s admin role.
     */
    function revokeRole(RoleRequest calldata req, bytes calldata signature) external;

    /**
     * @dev Revokes `req.role` from req.target.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If `req.target` had been granted `req.role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the signer must be `req.target`.
     */
    function renounceRole(RoleRequest calldata req, bytes calldata signature) external;
}
