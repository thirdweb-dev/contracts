// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./PermissionsEnumerable.sol";

/**
 *  The `SoulboundERC721A` extension smart contract is meant to be used with ERC721A contracts as its base. It
 *  provides the appropriate `before transfer` hook for ERC721A, where it checks whether a given transfer is
 *  valid to go through or not.
 *
 *  This contract uses the `Permissions` extension, and creates a role 'TRANSFER_ROLE'.
 *      - If `address(0)` holds the transfer role, then all transfers go through.
 *      - Else, a transfer goes through only if either the sender or recipient holds the transfe role.
 */

abstract contract SoulboundERC721A is PermissionsEnumerable {
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    event TransfersRestricted(bool isRestricted);

    /**
     *  @notice           Restrict transfers of NFTs.
     *  @dev              Restricting transfers means revoking the TRANSFER_ROLE from address(0). Making
     *                    transfers unrestricted means granting the TRANSFER_ROLE to address(0).
     *
     *  @param _toRestrict Whether to restrict transfers or not.
     */
    function restrictTransfers(bool _toRestrict) public virtual {
        if (_toRestrict) {
            _revokeRole(TRANSFER_ROLE, address(0));
        } else {
            _setupRole(TRANSFER_ROLE, address(0));
        }
    }

    /// @dev Returns whether transfers can be restricted in a given execution context.
    function _canRestrictTransfers() internal view virtual returns (bool);

    /// @dev See {ERC721A-_beforeTokenTransfers}.
    function _beforeTokenTransfers(address from, address to, uint256, uint256) internal virtual {
        // If transfers are restricted on the contract, we still want to allow burning and minting.
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(TRANSFER_ROLE, from) && !hasRole(TRANSFER_ROLE, to)) {
                revert("!TRANSFER_ROLE");
            }
        }
    }
}
