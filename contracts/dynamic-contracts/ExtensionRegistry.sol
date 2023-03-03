// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IExtensionRegistry.sol";

// Extensions
import "../extension/PermissionsEnumerable.sol";
import "lib/dynamic-contracts/src/presets/utils/ExtensionState.sol";
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";
import { BaseRouter } from "lib/dynamic-contracts/src/presets/BaseRouter.sol";

contract ExtensionRegistry is BaseRouter, PermissionsEnumerable {
    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _defaultAdmin, Extension[] memory _extensions) BaseRouter(_extensions) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether extensions can be set in the given execution context.
    function _canSetExtension() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
