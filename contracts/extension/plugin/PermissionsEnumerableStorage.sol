// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPermissionsEnumerable.sol";

/**
 *  @author  thirdweb.com
 */
library PermissionsEnumerableStorage {
    /// @custom:storage-location erc7201:permissions.enumerable.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("permissions.enumerable.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant PERMISSIONS_ENUMERABLE_STORAGE_POSITION =
        0x1ea2ed6cf13bfad376ba49bede85b663fef0b40eac197c5ac8e6f92ec4076100;

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
