// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  Internal imports    ==========
import "../IMap.sol";

import "../extension/PermissionsEnumerable.sol";
import "../extension/ERC2771Context.sol";
import "../../extension/Multicall.sol";

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

contract TWMultichainRegistryEntrypoint is PermissionsEnumerable, ERC2771Context, Multicall {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("TWMultichainRegistry");
    uint256 private constant VERSION = 1;

    address public immutable functionMap;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _functionMap, address[] memory _trustedForwarders) ERC2771Context(_trustedForwarders) {
        functionMap = _functionMap;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    fallback() external payable virtual {
        address extension = IMap(functionMap).getExtension(msg.sig);
        require(extension != address(0), "Function does not exist");

        _delegate(extension);
    }

    receive() external payable {}

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

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

    function _msgSender() internal view override(ERC2771Context, Permissions) returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view override(ERC2771Context, Permissions) returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
