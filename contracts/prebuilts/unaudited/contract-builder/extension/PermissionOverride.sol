// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *   ////////////
 *
 *   NOTE: This contract is a work in progress, and has not been audited.
 *
 *   ////////////
 */

library PermissionsStorage {
    bytes32 public constant PERMISSIONS_STORAGE_POSITION = keccak256("permissions.storage");

    struct Data {
        /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
        mapping(bytes32 => mapping(address => bool)) _hasRole;
        /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
        mapping(bytes32 => bytes32) _getRoleAdmin;
    }

    function permissionsStorage() internal pure returns (Data storage permissionsData) {
        bytes32 position = PERMISSIONS_STORAGE_POSITION;
        assembly {
            permissionsData.slot := position
        }
    }
}

contract PermissionOverrideCoreRouter {
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 private constant EXTENSION_ROLE = keccak256("EXTENSION_ROLE");

    function canSetContractURI(address _caller) public view returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _caller);
    }

    function canSetOwner(address _caller) public view returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _caller);
    }

    function canSetExtension(address _caller) public view returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _caller);
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][account];
    }
}
