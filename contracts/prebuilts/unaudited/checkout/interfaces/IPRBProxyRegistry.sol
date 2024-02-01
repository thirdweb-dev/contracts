// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IPRBProxy } from "./IPRBProxy.sol";
import { IPRBProxyPlugin } from "./IPRBProxyPlugin.sol";

/// @title IPRBProxyRegistry
/// @notice Deploys new proxies via CREATE2 and keeps a registry of owners to proxies. Proxies can only be deployed
/// once per owner, and they cannot be transferred. The registry also supports installing plugins, which are used
/// for extending the functionality of the proxy.
interface IPRBProxyRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to install a plugin that implements a method already implemented by another
    /// installed plugin.
    error PRBProxyRegistry_PluginMethodCollision(
        IPRBProxyPlugin currentPlugin, IPRBProxyPlugin newPlugin, bytes4 method
    );

    /// @notice Thrown when trying to uninstall an unknown plugin.
    error PRBProxyRegistry_PluginUnknown(IPRBProxyPlugin plugin);

    /// @notice Thrown when trying to install a plugin that doesn't implement any method.
    error PRBProxyRegistry_PluginWithZeroMethods(IPRBProxyPlugin plugin);

    /// @notice Thrown when a function requires the user to have a proxy.
    error PRBProxyRegistry_UserDoesNotHaveProxy(address user);

    /// @notice Thrown when a function requires the user to not have a proxy.
    error PRBProxyRegistry_UserHasProxy(address user, IPRBProxy proxy);

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new proxy is deployed.
    event DeployProxy(address indexed operator, address indexed owner, IPRBProxy proxy);

    /// @notice Emitted when a plugin is installed.
    event InstallPlugin(
        address indexed owner, IPRBProxy indexed proxy, IPRBProxyPlugin indexed plugin, bytes4[] methods
    );

    /// @notice Emitted when an envoy's permission is updated.
    event SetPermission(
        address indexed owner, IPRBProxy indexed proxy, address indexed envoy, address target, bool newPermission
    );

    /// @notice Emitted when a plugin is uninstalled.
    event UninstallPlugin(
        address indexed owner, IPRBProxy indexed proxy, IPRBProxyPlugin indexed plugin, bytes4[] methods
    );

    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @param owner The address of the user who will own the proxy.
    /// @param target The address of the target to delegate call to. Can be set to zero.
    /// @param data The call data to be passed to the target. Can be set to zero.
    struct ConstructorParams {
        address owner;
        address target;
        bytes data;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The release version of the proxy system, which applies to both the registry and deployed proxies.
    /// @dev This is stored in the registry rather than the proxy to save gas for end users.
    function VERSION() external view returns (string memory);

    /// @notice The parameters used in constructing the proxy, which the registry sets transiently during proxy
    /// deployment.
    /// @dev The proxy constructor fetches these parameters.
    function constructorParams() external view returns (address owner, address target, bytes memory data);

    /// @notice Retrieves the list of installed methods for the provided plugin.
    /// @dev An empty array is returned if the plugin is unknown.
    /// @param owner The proxy owner for the query.
    /// @param plugin The plugin for the query.
    function getMethodsByOwner(address owner, IPRBProxyPlugin plugin) external view returns (bytes4[] memory methods);

    /// @notice Retrieves the list of installed methods for the provided plugin.
    /// @dev An empty array is returned if the plugin is unknown.
    /// @param proxy The proxy for the query.
    /// @param plugin The plugin for the query.
    function getMethodsByProxy(
        IPRBProxy proxy,
        IPRBProxyPlugin plugin
    )
        external
        view
        returns (bytes4[] memory methods);

    /// @notice Retrieves a boolean flag that indicates whether the provided envoy has permission to call the provided
    /// target.
    /// @param owner The proxy owner for the query.
    /// @param envoy The address checked for permission to call the target.
    /// @param target The address of the target.
    function getPermissionByOwner(
        address owner,
        address envoy,
        address target
    )
        external
        view
        returns (bool permission);

    /// @notice Retrieves a boolean flag that indicates whether the provided envoy has permission to call the provided
    /// target.
    /// @param proxy The proxy for the query.
    /// @param envoy The address checked for permission to call the target.
    /// @param target The address of the target.
    function getPermissionByProxy(
        IPRBProxy proxy,
        address envoy,
        address target
    )
        external
        view
        returns (bool permission);

    /// @notice Retrieves the address of the plugin installed for the provided method selector.
    /// @dev The zero address is returned if no plugin is installed.
    /// @param owner The proxy owner for the query.
    /// @param method The method selector for the query.
    function getPluginByOwner(address owner, bytes4 method) external view returns (IPRBProxyPlugin plugin);

    /// @notice Retrieves the address of the plugin installed for the provided method selector.
    /// @dev The zero address is returned if no plugin is installed.
    /// @param proxy The proxy for the query.
    /// @param method The method selector for the query.
    function getPluginByProxy(IPRBProxy proxy, bytes4 method) external view returns (IPRBProxyPlugin plugin);

    /// @notice Retrieves the proxy for the provided user.
    /// @param user The user address for the query.
    function getProxy(address user) external view returns (IPRBProxy proxy);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new proxy for the caller.
    ///
    /// @dev Emits a {DeployProxy} event.
    ///
    /// Requirements:
    /// - The caller must not have a proxy.
    ///
    /// @return proxy The address of the newly deployed proxy.
    function deploy() external returns (IPRBProxy proxy);

    /// @notice This function performs two actions:
    /// 1. Deploys a new proxy for the caller
    /// 2. Delegate calls to the provided target, returning the data it gets back, and bubbling up any potential revert.
    ///
    /// @dev Emits a {DeployProxy} and {Execute} event.
    ///
    /// Requirements:
    /// - The caller must not have a proxy.
    /// - `target` must be a contract.
    ///
    /// @param target The address of the target.
    /// @param data Function selector plus ABI-encoded data.
    /// @return proxy The address of the newly deployed proxy.
    function deployAndExecute(address target, bytes calldata data) external returns (IPRBProxy proxy);

    /// @notice This function performs three actions:
    /// 1. Deploys a new proxy for the caller
    /// 2. Delegate calls to the provided target, returning the data it gets back, and bubbling up any potential revert.
    /// 3. Installs the provided plugin on the newly deployed proxy.
    ///
    /// @dev Emits a {DeployProxy}, {Execute}, and {InstallPlugin} event.
    ///
    /// Requirements:
    /// - The caller must not have a proxy.
    /// - See the requirements in `installPlugin`.
    /// - See the requirements in `execute`.
    ///
    /// @param target The address of the target.
    /// @param data Function selector plus ABI-encoded data.
    /// @param plugin The address of the plugin to install.
    /// @return proxy The address of the newly deployed proxy.
    function deployAndExecuteAndInstallPlugin(
        address target,
        bytes calldata data,
        IPRBProxyPlugin plugin
    )
        external
        returns (IPRBProxy proxy);

    /// @notice This function performs two actions:
    /// 1. Deploys a new proxy for the caller.
    /// 2. Installs the provided plugin on the newly deployed proxy.
    ///
    /// @dev Emits a {DeployProxy} and {InstallPlugin} event.
    ///
    /// Requirements:
    /// - The caller must not have a proxy.
    /// - See the requirements in `installPlugin`.
    ///
    /// @param plugin The address of the plugin to install.
    /// @return proxy The address of the newly deployed proxy.
    function deployAndInstallPlugin(IPRBProxyPlugin plugin) external returns (IPRBProxy proxy);

    /// @notice Deploys a new proxy for the provided user.
    ///
    /// @dev Emits a {DeployProxy} event.
    ///
    /// Requirements:
    /// - The user must not have a proxy already.
    ///
    /// @param user The address that will own the proxy.
    /// @return proxy The address of the newly deployed proxy.
    function deployFor(address user) external returns (IPRBProxy proxy);

    /// @notice Installs the provided plugin on the caller's proxy, and saves the list of methods implemented by the
    /// plugin so that they can be referenced later.
    ///
    /// @dev Emits an {InstallPlugin} event.
    ///
    /// Notes:
    /// - Installing a plugin is a potentially dangerous operation, because anyone can run the plugin.
    /// - Plugin methods that have the same selectors as {IPRBProxy.execute}, {IPRBProxy.owner}, and
    /// {IPRBProxy.registry} can be installed, but they can never be run.
    ///
    /// Requirements:
    /// - The caller must have a proxy.
    /// - The plugin must have at least one implemented method.
    /// - There must be no method collision with any other plugin installed by the caller.
    ///
    /// @param plugin The address of the plugin to install.
    function installPlugin(IPRBProxyPlugin plugin) external;

    /// @notice Gives or takes a permission from an envoy to call the provided target and function selector
    /// on behalf of the caller's proxy.
    ///
    /// @dev Emits a {SetPermission} event.
    ///
    /// Notes:
    /// - It is not an error to set the same permission.
    ///
    /// Requirements:
    /// - The caller must have a proxy.
    ///
    /// @param envoy The address of the account the caller is giving or taking permission from.
    /// @param target The address of the target.
    /// @param permission The boolean permission to set.
    function setPermission(address envoy, address target, bool permission) external;

    /// @notice Uninstalls the plugin from the caller's proxy, and removes the list of methods originally implemented by
    /// the plugin.
    ///
    /// @dev Emits an {UninstallPlugin} event.
    ///
    /// Requirements:
    /// - The caller must have a proxy.
    /// - The plugin must be a known, previously installed plugin.
    ///
    /// @param plugin The address of the plugin to uninstall.
    function uninstallPlugin(IPRBProxyPlugin plugin) external;
}
