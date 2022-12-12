// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

////////// NOTE(S) //////////
/**
 *  - A Signer-Credential pair hash can only be used/associated with one unique account.
 *
 *  - How does data fetching work?
 *      - Fetch all accounts for a single signer.
 *      - Fetch all signers for a single account.
 *      - Fetch the unique account for a signer-credential pair.
 */

contract AccountAdminMulti {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Signer => Accounts where signer is an actor.
    mapping(address => EnumerableSet.AddressSet) private signerToAccounts;

    /// @dev Account => Signers that are actors in account.
    mapping(address => EnumerableSet.AddressSet) private accountToSigners;

    /// @dev Signer-Credential pair => Account.
    mapping(bytes32 => address) private pairHashToAccount;
}
