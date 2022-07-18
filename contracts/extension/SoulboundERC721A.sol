// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Permissions.sol";

/**
 *  The `SoulboundERC721A` extension smart contract is meant to be used with ERC721A contracts as its base. It
 *  provides the appropriate `before transfer` hook for ERC721A, where it checks whether a given transfer is 
 *  valid to go through or not.
 *
 *  This contract uses the `Permissions` extension, and creates a role 'TRANSFER_ROLE'.
 *      - If `address(0)` holds the transfer role, then all transfers go through.
 *      - Else, a transfer goes through only if either the sender or recipient holds the transfe role.
 */

contract SoulboundERC721A is Permissions {

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");


    /// @dev See {ERC721A-_beforeTokenTransfers}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256,
        uint256
    ) internal virtual {

        // If transfers are restricted on the contract, we still want to allow burning and minting.
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(TRANSFER_ROLE, from) && !hasRole(TRANSFER_ROLE, to)) {
                revert("!TRANSFER_ROLE");
            }
        }
    }

}