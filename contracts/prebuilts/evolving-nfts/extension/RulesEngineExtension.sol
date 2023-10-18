// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import { PermissionsStorage } from "../../../extension/upgradeable/Permissions.sol";
import { RulesEngine } from "../../../extension/upgradeable/RulesEngine.sol";

contract RulesEngineExtension is RulesEngine {
    /// @dev Returns whether the rules of the contract can be set in the given execution context.
    function _canSetRules() internal view virtual override returns (bool) {
        return _hasRole(keccak256("MINTER_ROLE"), msg.sender);
    }

    /// @dev Returns whether the rules engine used by the contract can be overriden in the given execution context.
    function _canOverrideRulesEngine() internal view virtual override returns (bool) {
        // DEFAULT_ADMIN_ROLE
        return _hasRole(0x00, msg.sender);
    }

    /// @dev Checks whether an account has a particular role.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._hasRole[_role][_account];
    }
}
