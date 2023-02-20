// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "./interface/IRouter.sol";

abstract contract Router is IRouter {
    fallback() external payable virtual {
        /// @dev delegate calls the appropriate implementation smart contract for a given function.
        address pluginAddress = getImplementationForFunction(msg.sig);
        _delegate(pluginAddress);
    }

    receive() external payable virtual {}

    /// @dev delegateCalls an `implementation` smart contract.
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

    /// @dev Unimplemented. Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address);
}
