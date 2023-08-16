// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  Internal imports    ==========

import "../../../extension/plugin/PermissionsEnumerableLogic.sol";
import "../../../extension/plugin/ERC2771ContextLogic.sol";
import "../../../extension/Multicall.sol";
import "../../../extension/plugin/Router.sol";

/**
 *
 *      "Inherited by entrypoint" extensions.
 *      - PermissionsEnumerable
 *      - ERC2771Context
 *      - Multicall
 *
 *      "NOT inherited by entrypoint" extensions.
 *      - TWMultichainRegistry
 */

contract TWMultichainRegistryRouter is PermissionsEnumerableLogic, ERC2771ContextLogic, Router {
    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _pluginMap, address[] memory _trustedForwarders)
        ERC2771ContextLogic(_trustedForwarders)
        Router(_pluginMap)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Overridable Permissions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _msgSender() internal view override(ERC2771ContextLogic, PermissionsLogic) returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view override(ERC2771ContextLogic, PermissionsLogic) returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
