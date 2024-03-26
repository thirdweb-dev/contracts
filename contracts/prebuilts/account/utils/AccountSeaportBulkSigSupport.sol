// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { SeaportEIP1271 } from "../../../extension/SeaportEIP1271.sol";
import { AccountPermissions, AccountPermissionsStorage } from "../../../extension/upgradeable/AccountPermissions.sol";
import { EnumerableSet } from "../../../external-deps/openzeppelin/utils/structs/EnumerableSet.sol";

contract AccountSeaportBulkSigSupport is SeaportEIP1271 {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor() SeaportEIP1271("Account", "1") {}

    /// @notice Returns whether a given signer is an authorized signer for the contract.
    function _isAuthorizedSigner(address _signer) internal view virtual override returns (bool authorized) {
        // is signer an admin?
        if (AccountPermissionsStorage.data().isAdmin[_signer]) {
            authorized = true;
        }

        address caller = msg.sender;
        EnumerableSet.AddressSet storage approvedTargets = AccountPermissionsStorage.data().approvedTargets[_signer];

        require(
            approvedTargets.contains(caller) || (approvedTargets.length() == 1 && approvedTargets.at(0) == address(0)),
            "Account: caller not approved target."
        );

        // is signer an active signer of account?
        AccountPermissions.SignerPermissionsStatic memory permissions = AccountPermissionsStorage
            .data()
            .signerPermissions[_signer];
        if (
            permissions.startTimestamp <= block.timestamp &&
            block.timestamp < permissions.endTimestamp &&
            AccountPermissionsStorage.data().approvedTargets[_signer].length() > 0
        ) {
            authorized = true;
        }
    }
}
