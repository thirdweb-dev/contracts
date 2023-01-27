// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Router.sol";
import "./PluginRegistry.sol";

import "../PermissionsEnumerable.sol";

contract RouterOptInUpgradeable is Router, PermissionsEnumerable {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PLUGIN_ADMIN_ROLE = keccak256("PLUGIN_ADMIN_ROLE");

    address public immutable pluginRegistry;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _pluginAdmin,
        address _pluginMap,
        address _pluginRegistry
    ) Router(_pluginMap) {
        pluginRegistry = _pluginRegistry;

        _setupRole(PLUGIN_ADMIN_ROLE, _pluginAdmin);
        _setRoleAdmin(PLUGIN_ADMIN_ROLE, PLUGIN_ADMIN_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view virtual override returns (bool) {
        return hasRole(PLUGIN_ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether a plugin is a safe, authorized plugin.
    function _isAuthorizedPlugin(bytes4 _functionSelector, address _plugin) internal view override returns (bool) {
        return PluginRegistry(pluginRegistry).isApprovedPlugin(_functionSelector, _plugin);
    }
}
