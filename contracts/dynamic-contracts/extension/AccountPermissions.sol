// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/IAccountPermissions.sol";
import "../../openzeppelin-presets/utils/cryptography/EIP712.sol";
import "../../openzeppelin-presets/utils/structs/EnumerableSet.sol";

library AccountPermissionsStorage {
    bytes32 public constant ACCOUNT_PERMISSIONS_STORAGE_POSITION = keccak256("account.permissions.storage");

    struct Data {
        /// @dev Map from address => whether the address is an admin.
        mapping(address => bool) isAdmin;
        /// @dev Map from keccak256 hash of a role => active restrictions for that role.
        mapping(bytes32 => IAccountPermissions.RoleStatic) roleRestrictions;
        /// @dev Map from address => the role held by that address.
        mapping(address => bytes32) roleOfAccount;
        /// @dev Mapping from a signed request UID => whether the request is processed.
        mapping(bytes32 => bool) executed;
        /// @dev Map from keccak256 hash of a role to its approved targets.
        mapping(bytes32 => EnumerableSet.AddressSet) approvedTargets;
        /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
    }

    function accountPermissionsStorage() internal pure returns (Data storage accountPermissionsData) {
        bytes32 position = ACCOUNT_PERMISSIONS_STORAGE_POSITION;
        assembly {
            accountPermissionsData.slot := position
        }
    }
}

abstract contract AccountPermissions is IAccountPermissions, EIP712 {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 private constant TYPEHASH =
        keccak256(
            "RoleRequest(bytes32 role,address target,uint8 action,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    modifier onlyAdmin() virtual {
        require(isAdmin(msg.sender), "AccountPermissions: caller is not an admin");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds / removes an account as an admin.
    function setAdmin(address _account, bool _isAdmin) external virtual onlyAdmin {
        _setAdmin(_account, _isAdmin);
    }

    /// @notice Sets the restrictions for a given role.
    function setRoleRestrictions(RoleRestrictions calldata _restrictions) external virtual onlyAdmin {
        require(_restrictions.role != bytes32(0), "AccountPermissions: role cannot be empty");

        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        data.roleRestrictions[_restrictions.role] = RoleStatic(
            _restrictions.role,
            _restrictions.maxValuePerTransaction,
            _restrictions.startTimestamp,
            _restrictions.endTimestamp
        );

        uint256 len = _restrictions.approvedTargets.length;
        delete data.approvedTargets[_restrictions.role];
        for (uint256 i = 0; i < len; i++) {
            data.approvedTargets[_restrictions.role].add(_restrictions.approvedTargets[i]);
        }

        emit RoleUpdated(_restrictions.role, _restrictions);
    }

    /// @notice Grant / revoke a role from a given signer.
    function changeRole(RoleRequest calldata _req, bytes calldata _signature) external virtual {
        require(_req.role != bytes32(0), "AccountPermissions: role cannot be empty");
        require(
            _req.validityStartTimestamp < block.timestamp && block.timestamp < _req.validityEndTimestamp,
            "AccountPermissions: invalid validity period"
        );

        (bool success, address signer) = verifyRoleRequest(_req, _signature);

        require(success, "AccountPermissions: invalid signature");

        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        data.executed[_req.uid] = true;

        if (_req.action == RoleAction.GRANT) {
            data.roleOfAccount[_req.target] = _req.role;
            data.roleMembers[_req.role].add(_req.target);
        } else {
            delete data.roleOfAccount[_req.target];
            data.roleMembers[_req.role].remove(_req.target);
        }

        emit RoleAssignment(_req.role, _req.target, signer, _req);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the given account is an admin.
    function isAdmin(address _account) public view virtual returns (bool) {
        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        return data.isAdmin[_account];
    }

    /// @notice Returns the role held by a given account along with its restrictions.
    function getRoleRestrictionsForAccount(address _account) external view virtual returns (RoleRestrictions memory) {
        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        bytes32 role = data.roleOfAccount[_account];
        RoleStatic memory roleRestrictions = data.roleRestrictions[role];

        return
            RoleRestrictions(
                role,
                data.approvedTargets[role].values(),
                roleRestrictions.maxValuePerTransaction,
                roleRestrictions.startTimestamp,
                roleRestrictions.endTimestamp
            );
    }

    /// @notice Returns the role restrictions for a given role.
    function getRoleRestrictions(bytes32 _role) external view virtual returns (RoleRestrictions memory) {
        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        RoleStatic memory roleRestrictions = data.roleRestrictions[_role];

        return
            RoleRestrictions(
                _role,
                data.approvedTargets[_role].values(),
                roleRestrictions.maxValuePerTransaction,
                roleRestrictions.startTimestamp,
                roleRestrictions.endTimestamp
            );
    }

    /// @notice Returns all accounts that have a role.
    function getAllRoleMembers(bytes32 _role) external view virtual returns (address[] memory) {
        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        return data.roleMembers[_role].values();
    }

    /// @dev Verifies that a request is signed by an authorized account.
    function verifyRoleRequest(RoleRequest calldata req, bytes calldata signature)
        public
        view
        virtual
        returns (bool success, address signer)
    {
        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        signer = _recoverAddress(req, signature);
        success = !data.executed[req.uid] && isAdmin(signer);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Runs after every `changeRole` run.
    function _afterChangeRole(RoleRequest calldata _req) internal virtual;

    /// @notice Makes the given account an admin.
    function _setAdmin(address _account, bool _isAdmin) internal virtual {
        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();
        data.isAdmin[_account] = _isAdmin;

        emit AdminUpdated(_account, _isAdmin);
    }

    /// @dev Returns the address of the signer of the request.
    function _recoverAddress(RoleRequest calldata _req, bytes calldata _signature)
        internal
        view
        virtual
        returns (address)
    {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Encodes a request for recovery of the signer in `recoverAddress`.
    function _encodeRequest(RoleRequest calldata _req) internal pure virtual returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.role,
                _req.target,
                _req.action,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid
            );
    }
}
