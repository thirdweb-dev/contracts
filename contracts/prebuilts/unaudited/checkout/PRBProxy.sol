// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IPRBProxy } from "./interfaces/IPRBProxy.sol";
import { IPRBProxyPlugin } from "./interfaces/IPRBProxyPlugin.sol";
import { IPRBProxyRegistry } from "./interfaces/IPRBProxyRegistry.sol";

/*

██████╗ ██████╗ ██████╗ ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
██████╔╝██████╔╝██████╔╝██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝
██╔═══╝ ██╔══██╗██╔══██╗██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝
██║     ██║  ██║██████╔╝██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝

*/

/// @title PRBProxy
/// @dev See the documentation in {IPRBProxy}.
contract PRBProxy is IPRBProxy {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxy
    address public immutable override owner;

    /// @inheritdoc IPRBProxy
    IPRBProxyRegistry public immutable override registry;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates the proxy by fetching the constructor params from the registry, optionally delegate calling
    /// to a target contract if one is provided.
    /// @dev The rationale of this approach is to have the proxy's CREATE2 address not depend on any constructor params.
    constructor() {
        registry = IPRBProxyRegistry(msg.sender);
        (address owner_, address target, bytes memory data) = registry.constructorParams();
        owner = owner_;
        if (target != address(0)) {
            _execute(target, data);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  FALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Fallback function used to run plugins.
    /// @dev WARNING: anyone can call this function and thus run any installed plugin.
    fallback(bytes calldata data) external payable returns (bytes memory response) {
        // Check if the function selector points to a known installed plugin.
        IPRBProxyPlugin plugin = registry.getPluginByOwner({ owner: owner, method: msg.sig });
        if (address(plugin) == address(0)) {
            revert PRBProxy_PluginNotInstalledForMethod({ caller: msg.sender, owner: owner, method: msg.sig });
        }

        // Delegate call to the plugin.
        bool success;
        (success, response) = address(plugin).delegatecall(data);

        // Log the plugin run.
        emit RunPlugin(plugin, data, response);

        // Check if the call was successful or not.
        if (!success) {
            // If there is return data, the delegate call reverted with a reason or a custom error, which we bubble up.
            if (response.length > 0) {
                assembly {
                    let returndata_size := mload(response)
                    revert(add(32, response), returndata_size)
                }
            } else {
                revert PRBProxy_PluginReverted(plugin);
            }
        }
    }

    /// @dev Called when `msg.value` is not zero and the call data is empty.
    receive() external payable { }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxy
    function execute(address target, bytes calldata data) external payable override returns (bytes memory response) {
        // Check that the caller is either the owner or an envoy with permission.
        if (owner != msg.sender) {
            bool permission = registry.getPermissionByOwner({ owner: owner, envoy: msg.sender, target: target });
            if (!permission) {
                revert PRBProxy_ExecutionUnauthorized({ owner: owner, caller: msg.sender, target: target });
            }
        }

        // Delegate call to the target contract, and handle the response.
        response = _execute(target, data);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Executes a DELEGATECALL to the provided target with the provided data.
    /// @dev Shared logic between the constructor and the `execute` function.
    function _execute(address target, bytes memory data) internal returns (bytes memory response) {
        // Check that the target is a contract.
        if (target.code.length == 0) {
            revert PRBProxy_TargetNotContract(target);
        }

        // Delegate call to the target contract.
        bool success;
        (success, response) = target.delegatecall(data);

        // Log the execution.
        emit Execute(target, data, response);

        // Check if the call was successful or not.
        if (!success) {
            // If there is return data, the delegate call reverted with a reason or a custom error, which we bubble up.
            if (response.length > 0) {
                assembly {
                    // The length of the data is at `response`, while the actual data is at `response + 32`.
                    let returndata_size := mload(response)
                    revert(add(response, 32), returndata_size)
                }
            } else {
                revert PRBProxy_ExecutionReverted();
            }
        }
    }
}
