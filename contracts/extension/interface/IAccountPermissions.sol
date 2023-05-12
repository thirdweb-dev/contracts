// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IAccountPermissions {
    /*///////////////////////////////////////////////////////////////
                                Types
    //////////////////////////////////////////////////////////////*/

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

    /**
     *  @notice Restrictions that can be applied to a given role.
     *
     *  @param role The unique role identifier.
     *  @param approvedTargets The list of approved targets that a role holder can call using the smart wallet.
     *  @param maxValuePerTransaction The maximum value that can be transferred by a role holder in a single transaction.
     *  @param startTimestamp The UNIX timestamp at and after which a role holder can call the approved targets.
     *  @param endTimestamp The UNIX timestamp at and after which a role holder can no longer call the approved targets.
     */
    struct Role {
        bytes32 role;
        address[] approvedTargets;
        uint256 maxValuePerTransaction;
        uint128 startTimestamp;
        uint128 endTimestamp;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the restrictions for a given role are updated.
    event RoleUpdated(bytes32 indexed role, Role restrictions);

    /// @notice Emitted when a role is granted / revoked / renounced by an authorized party.
    event RoleAssignment(bytes32 indexed role, address indexed account, RoleRequest request);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the role held by a given account.
    function getRoleOfAccount(address account) external view returns (Role memory role);

    /// @notice Returns the role restrictions for a given role.
    function getRoleRestrictions(bytes32 role) external view returns (Role memory restrictions);

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the restrictions for a given role.
    function setRoleRestrictions(Role calldata role) external;

    /// @notice Grant / revoke / renounce a role from a given signer.
    function changeRole(RoleRequest calldata req, bytes calldata signature) external;
}
