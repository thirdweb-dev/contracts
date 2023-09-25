// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { PermissionsStorage } from "../Permissions.sol";

contract PermissionsInternal {
    /*///////////////////////////////////////////////////////////////
                        Internal View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Checks whether an account has a particular role.
     *  @dev            Returns `true` if `account` has been granted `role`.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return PermissionsStorage.data()._hasRole[role][account];
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
    function _hasRoleWithSwitch(bytes32 role, address account) internal view returns (bool) {
        if (!PermissionsStorage.data()._hasRole[role][address(0)]) {
            return PermissionsStorage.data()._hasRole[role][account];
        }

        return true;
    }
}
