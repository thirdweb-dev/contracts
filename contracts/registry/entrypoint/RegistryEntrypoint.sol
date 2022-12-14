// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  Internal imports    ==========

import "../extension/PermissionsEnumerableLogic.sol";
import "../extension/ERC2771ContextLogic.sol";
import "../../extension/Multicall.sol";
import "../../extension/plugin/Entrypoint.sol";

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

contract TWMultichainRegistryEntrypoint is PermissionsEnumerableLogic, ERC2771ContextLogic, Multicall, Entrypoint {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("TWMultichainRegistry");
    uint256 private constant VERSION = 1;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _functionMap, address[] memory _trustedForwarders)
        ERC2771ContextLogic(_trustedForwarders)
        Entrypoint(_functionMap)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /*///////////////////////////////////////////////////////////////
                        Overridable Permissions
    //////////////////////////////////////////////////////////////*/

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
