// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IPRBProxyPlugin } from "./IPRBProxyPlugin.sol";
import { IPRBProxyRegistry } from "./IPRBProxyRegistry.sol";

/// @title IPRBProxy
/// @notice Proxy contract to compose transactions on behalf of the owner.
interface IPRBProxy {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a target contract reverts without a specified reason.
    error PRBProxy_ExecutionReverted();

    /// @notice Thrown when an unauthorized account tries to execute a delegate call.
    error PRBProxy_ExecutionUnauthorized(address owner, address caller, address target);

    /// @notice Thrown when the fallback function fails to find an installed plugin for the method selector.
    error PRBProxy_PluginNotInstalledForMethod(address caller, address owner, bytes4 method);

    /// @notice Thrown when a plugin execution reverts without a specified reason.
    error PRBProxy_PluginReverted(IPRBProxyPlugin plugin);

    /// @notice Thrown when a non-contract address is passed as the target.
    error PRBProxy_TargetNotContract(address target);

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a target contract is delegate called.
    event Execute(address indexed target, bytes data, bytes response);

    /// @notice Emitted when a plugin is run for a provided method.
    event RunPlugin(IPRBProxyPlugin indexed plugin, bytes data, bytes response);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the owner account or contract, which controls the proxy.
    function owner() external view returns (address);

    /// @notice The address of the registry that has deployed this proxy.
    function registry() external view returns (IPRBProxyRegistry);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Delegate calls to the provided target contract by forwarding the data. It returns the data it
    /// gets back, and bubbles up any potential revert.
    ///
    /// @dev Emits an {Execute} event.
    ///
    /// Requirements:
    /// - The caller must be either the owner or an envoy with permission.
    /// - `target` must be a contract.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return response The response received from the target contract, if any.
    function execute(address target, bytes calldata data) external payable returns (bytes memory response);
}
