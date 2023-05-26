// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IAccountPermissions {
    /*///////////////////////////////////////////////////////////////
                                Types
    //////////////////////////////////////////////////////////////*/

    /// @notice Roles can be granted or revoked by an authorized party.
    enum RoleAction {
        GRANT,
        REVOKE
    }

    /**
     *  @notice The payload that must be signed by an authorized wallet to grant / revoke a role.
     *
     *  @param role The role to grant / revoke.
     *  @param target The address to grant / revoke the role from.
     *  @param action Whether to grant or revoke the role.
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
    struct RoleRestrictions {
        bytes32 role;
        address[] approvedTargets;
        uint256 maxValuePerTransaction;
        uint128 startTimestamp;
        uint128 endTimestamp;
    }

    /**
     *  @notice Internal struct for storing roles without approved targets
     *
     *  @param role The unique role identifier.
     *  @param maxValuePerTransaction The maximum value that can be transferred by a role holder in a single transaction.
     *  @param startTimestamp The UNIX timestamp at and after which a role holder can call the approved targets.
     *  @param endTimestamp The UNIX timestamp at and after which a role holder can no longer call the approved targets.
     */
    struct RoleStatic {
        bytes32 role;
        uint256 maxValuePerTransaction;
        uint128 startTimestamp;
        uint128 endTimestamp;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the restrictions for a given role are updated.
    event RoleUpdated(bytes32 indexed role, RoleRestrictions restrictions);

    /// @notice Emitted when a role is granted / revoked by an authorized party.
    event RoleAssignment(bytes32 indexed role, address indexed account, address indexed signer, RoleRequest request);

    /// @notice Emitted when an admin is set or removed.
    event AdminUpdated(address indexed account, bool isAdmin);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the given account is an admin.
    function isAdmin(address account) external view returns (bool);

    /// @notice Returns the role held by a given account along with its restrictions.
    function getRoleRestrictionsForAccount(address account) external view returns (RoleRestrictions memory role);

    /// @notice Returns the role restrictions for a given role.
    function getRoleRestrictions(bytes32 role) external view returns (RoleRestrictions memory restrictions);

    /// @notice Returns all accounts that have a role.
    function getAllRoleMembers(bytes32 role) external view returns (address[] memory members);

    /// @dev Verifies that a request is signed by an authorized account.
    function verifyRoleRequest(RoleRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds / removes an account as an admin.
    function setAdmin(address account, bool isAdmin) external;

    /// @notice Sets the restrictions for a given role.
    function setRoleRestrictions(RoleRestrictions calldata role) external;

    /// @notice Grant / revoke a role from a given signer.
    function changeRole(RoleRequest calldata req, bytes calldata signature) external;
}
