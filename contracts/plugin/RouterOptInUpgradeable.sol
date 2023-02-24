// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TWRouter.sol";
import "./ExtensionRegistry.sol";

import "../extension/PermissionsEnumerable.sol";

contract RouterOptInUpgradeable is TWRouter, PermissionsEnumerable {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant EXTENSION_ADMIN_ROLE = keccak256("EXTENSION_ADMIN_ROLE");

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _extensionAdmin,
        address _extensionRegistry,
        string[] memory _extensionNames
    ) TWRouter(_extensionRegistry, _extensionNames) {
        _setupRole(EXTENSION_ADMIN_ROLE, _extensionAdmin);
        _setRoleAdmin(EXTENSION_ADMIN_ROLE, EXTENSION_ADMIN_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        return hasRole(EXTENSION_ADMIN_ROLE, msg.sender);
    }
}
