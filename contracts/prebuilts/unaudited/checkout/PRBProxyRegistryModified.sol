// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IPRBProxy } from "@prb/proxy/src/interfaces/IPRBProxy.sol";
import { IPRBProxyPlugin } from "@prb/proxy/src/interfaces/IPRBProxyPlugin.sol";
import { IPRBProxyRegistry } from "@prb/proxy/src/interfaces/IPRBProxyRegistry.sol";
import { PRBProxy } from "@prb/proxy/src/PRBProxy.sol";

/// @author Modified from prb-proxy (https://github.com/PaulRBerg/prb-proxy/blob/main/src/PRBProxyRegistry.sol)
/// @title PRBProxyRegistry
/// @dev See the documentation in {IPRBProxyRegistry}.
contract PRBProxyRegistryModified is IPRBProxyRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    string public constant override VERSION = "4.0.2";

    /// @dev Magic value to override target permissions. Holders can execute on any target.
    address public constant MAGIC_TARGET = address(0x42);

    /*//////////////////////////////////////////////////////////////////////////
                                USER-FACING STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    ConstructorParams public override constructorParams;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    mapping(address owner => mapping(IPRBProxyPlugin plugin => bytes4[] methods)) internal _methods;

    mapping(address owner => mapping(address envoy => mapping(address target => bool permission)))
        internal _permissions;

    mapping(address owner => mapping(bytes4 method => IPRBProxyPlugin plugin)) internal _plugins;

    mapping(address owner => IPRBProxy proxy) internal _proxies;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks that the caller has a proxy.
    modifier onlyCallerWithProxy() {
        if (address(_proxies[msg.sender]) == address(0)) {
            revert PRBProxyRegistry_UserDoesNotHaveProxy(msg.sender);
        }
        _;
    }

    /// @notice Check that the user does not have a proxy.
    modifier onlyNonProxyOwner(address user) {
        IPRBProxy proxy = _proxies[user];
        if (address(proxy) != address(0)) {
            revert PRBProxyRegistry_UserHasProxy(user, proxy);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    function getMethodsByOwner(address owner, IPRBProxyPlugin plugin) external view returns (bytes4[] memory methods) {
        methods = _methods[owner][plugin];
    }

    /// @inheritdoc IPRBProxyRegistry
    function getMethodsByProxy(
        IPRBProxy proxy,
        IPRBProxyPlugin plugin
    ) external view returns (bytes4[] memory methods) {
        methods = _methods[proxy.owner()][plugin];
    }

    /// @inheritdoc IPRBProxyRegistry
    function getPermissionByOwner(
        address owner,
        address envoy,
        address target
    ) external view returns (bool permission) {
        permission = _permissions[owner][envoy][target] || _permissions[owner][envoy][MAGIC_TARGET];
    }

    /// @inheritdoc IPRBProxyRegistry
    function getPermissionByProxy(
        IPRBProxy proxy,
        address envoy,
        address target
    ) external view returns (bool permission) {
        permission = _permissions[proxy.owner()][envoy][target] || _permissions[proxy.owner()][envoy][MAGIC_TARGET];
    }

    /// @inheritdoc IPRBProxyRegistry
    function getPluginByOwner(address owner, bytes4 method) external view returns (IPRBProxyPlugin plugin) {
        plugin = _plugins[owner][method];
    }

    /// @inheritdoc IPRBProxyRegistry
    function getPluginByProxy(IPRBProxy proxy, bytes4 method) external view returns (IPRBProxyPlugin plugin) {
        plugin = _plugins[proxy.owner()][method];
    }

    /// @inheritdoc IPRBProxyRegistry
    function getProxy(address user) external view returns (IPRBProxy proxy) {
        proxy = _proxies[user];
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    function deploy() external override onlyNonProxyOwner(msg.sender) returns (IPRBProxy proxy) {
        proxy = _deploy({ owner: msg.sender, target: address(0), data: "" });
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployAndExecute(
        address target,
        bytes calldata data
    ) external override onlyNonProxyOwner(msg.sender) returns (IPRBProxy proxy) {
        proxy = _deploy({ owner: msg.sender, target: target, data: data });
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployFor(address user) external override onlyNonProxyOwner(user) returns (IPRBProxy proxy) {
        proxy = _deploy({ owner: user, target: address(0), data: "" });
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployAndExecuteAndInstallPlugin(
        address target,
        bytes calldata data,
        IPRBProxyPlugin plugin
    ) external override onlyNonProxyOwner(msg.sender) returns (IPRBProxy proxy) {
        proxy = _deploy({ owner: msg.sender, target: target, data: data });
        _installPlugin(plugin);
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployAndInstallPlugin(
        IPRBProxyPlugin plugin
    ) external onlyNonProxyOwner(msg.sender) returns (IPRBProxy proxy) {
        proxy = _deploy({ owner: msg.sender, target: address(0), data: "" });
        _installPlugin(plugin);
    }

    /// @inheritdoc IPRBProxyRegistry
    function installPlugin(IPRBProxyPlugin plugin) external override onlyCallerWithProxy {
        _installPlugin(plugin);
    }

    /// @inheritdoc IPRBProxyRegistry
    function setPermission(address envoy, address target, bool permission) external override onlyCallerWithProxy {
        address owner = msg.sender;
        _permissions[owner][envoy][target] = permission;
        emit SetPermission(owner, _proxies[owner], envoy, target, permission);
    }

    /// @inheritdoc IPRBProxyRegistry
    function uninstallPlugin(IPRBProxyPlugin plugin) external override onlyCallerWithProxy {
        // Retrieve the methods originally installed by this plugin.
        address owner = msg.sender;
        bytes4[] memory methods = _methods[owner][plugin];

        // The plugin must be a known, previously installed plugin.
        uint256 length = methods.length;
        if (length == 0) {
            revert PRBProxyRegistry_PluginUnknown(plugin);
        }

        // Uninstall every method in the list.
        for (uint256 i = 0; i < length; ) {
            delete _plugins[owner][methods[i]];
            unchecked {
                i += 1;
            }
        }

        // Remove the methods from the reverse mapping.
        delete _methods[owner][plugin];

        // Log the plugin uninstallation.
        emit UninstallPlugin(owner, _proxies[owner], plugin, methods);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _deploy(address owner, address target, bytes memory data) internal returns (IPRBProxy proxy) {
        // Use the address of the owner as the CREATE2 salt.
        bytes32 salt = bytes32(abi.encodePacked(owner));

        // Set the owner and empty out the target and the data to prevent reentrancy.
        constructorParams = ConstructorParams({ owner: owner, target: target, data: data });

        // Deploy the proxy with CREATE2.
        proxy = new PRBProxy{ salt: salt }();
        delete constructorParams;

        // Associate the owner and the proxy.
        _proxies[owner] = proxy;

        // Log the creation of the proxy.
        emit DeployProxy({ operator: msg.sender, owner: owner, proxy: proxy });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _installPlugin(IPRBProxyPlugin plugin) internal {
        // Retrieve the methods to install.
        bytes4[] memory methods = plugin.getMethods();

        // The plugin must implement at least one method.
        uint256 length = methods.length;
        if (length == 0) {
            revert PRBProxyRegistry_PluginWithZeroMethods(plugin);
        }

        // Install every method in the list.
        address owner = msg.sender;
        for (uint256 i = 0; i < length; ) {
            // Check for collisions.
            bytes4 method = methods[i];
            if (address(_plugins[owner][method]) != address(0)) {
                revert PRBProxyRegistry_PluginMethodCollision({
                    currentPlugin: _plugins[owner][method],
                    newPlugin: plugin,
                    method: method
                });
            }
            _plugins[owner][method] = plugin;
            unchecked {
                i += 1;
            }
        }

        // Set the methods in the reverse mapping.
        _methods[owner][plugin] = methods;

        // Log the plugin installation.
        emit InstallPlugin(owner, _proxies[owner], plugin, methods);
    }
}
