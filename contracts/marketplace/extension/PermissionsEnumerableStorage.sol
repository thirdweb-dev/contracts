// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../extension/interface/IPermissionsEnumerable.sol";

library PermissionsEnumerableStorage {
    bytes32 public constant PERMISSIONS_ENUMERABLE_STORAGE_POSITION = keccak256("permissions.enumerable.storage");

    /**
     *  @notice A data structure to store data of members for a given role.
     *
     *  @param index    Current index in the list of accounts that have a role.
     *  @param members  map from index => address of account that has a role
     *  @param indexOf  map from address => index which the account has.
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    struct Data {
        /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
        mapping(bytes32 => RoleMembers) roleMembers;
    }

    function permissionsEnumerableStorage() internal pure returns (Data storage permissionsEnumerableData) {
        bytes32 position = PERMISSIONS_ENUMERABLE_STORAGE_POSITION;
        assembly {
            permissionsEnumerableData.slot := position
        }
    }
}
