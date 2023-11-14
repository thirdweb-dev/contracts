// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../eip/interface/IERC1155.sol";

interface ITeamsManager is IERC1155 {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice The status of a member in a team.
     *
     *  @param OWNER The owner of the team. This address is the super-admin. An owner can invite admins or non-admins to the team.
     *               There is only one owner per team; this status can be renounced only upon another address accepting an invitation
     *               to take this role.
     *
     *  @param ADMIN The admin of the team. An admin can add or remove non-admin members. There can be multiple admins per team. This
     *               status can be renounced, or revoked by the owner.
     *
     *  @param MEMBER A non-admin member of the team. A member can be invited by an admin or owner. This status can be renounced, or revoked
     *                by an admin or owner.
     */
    enum Status {
        OWNER,
        ADMIN,
        MEMBER
    }

    /**
     *  @notice The parameters of an invitation to join a team.
     *
     *  @param member The address of the member being invited.
     *  @param status The status to grant to the invited member.
     *  @param deadline The deadline by which the invitation must be accepted.
     */
    struct Invitation {
        // 1 storage slot
        uint32 teamId; //  ─┐ 4 bytes
        address member; //  | 20 bytes
        Status status; //   | 1 bytes
        uint56 deadline; //─┘ 7 bytes
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Create a team. Mints an ERC-1155 token representing the team.
     *
     *  @param owner The owner of the team.
     *  @param metadataURI The NFT metadata URI of the team.
     */
    function createTeam(address owner, string calldata metadataURI) external returns (uint256 teamId);

    /**
     *  @notice Transfer a team's ownership to another address. The caller must be the owner of the team.
     *
     *  @param invitation The invitation to transfer ownership. The specified status must be OWNER.
     */
    function transferTeamOwnership(Invitation calldata invitation) external;

    /**
     *  @notice Invite a member to a team. The caller must have appropriate team status based on the status of the member being invited.
     *
     *  @param invitation The invitation to join the team.
     */
    function inviteMember(Invitation calldata invitation) external;

    /**
     *  @notice Accept an invitation to join a team.
     *
     *  @param teamId The ID of the team.
     */
    function acceptInvite(uint256 teamId) external;

    /**
     *  @notice Remove a team member. The caller must have appropriate team status based on the status of the member being removed.
     *
     *  @param teamId The ID of the team.
     *  @param member The address of the member to remove.
     */
    function removeMember(uint256 teamId, address member) external;

    /**
     *  @notice Leave a team. The caller is removed from the team.
     *
     *  @param teamId The ID of the team.
     */
    function leaveTeam(uint256 teamId) external;

    /**
     *  @notice Deletes a team. The caller must be the owner of the team.
     *
     *  @param teamId The ID of the team.
     */
    function deleteTeam(uint256 teamId) external;

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the owner of a team.
    function teamOwner(uint256 teamId) external view returns (address);

    /// @notice Returns whether an address is an admin of a team.
    function isAdmin(uint256 teamId, address member) external view returns (bool);

    /// @notice Returns whether an address is a non-admin member of a team.
    function isMember(uint256 teamId, address member) external view returns (bool);
}
