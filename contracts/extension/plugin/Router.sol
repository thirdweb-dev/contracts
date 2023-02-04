// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRouter {
    fallback() external payable;

    function getImplementationForFunction(bytes4 _functionSelector) external view returns (address);
}

abstract contract Router is IRouter {
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    fallback() external payable virtual {
        address pluginAddress = getImplementationForFunction(msg.sig);
        _delegate(pluginAddress);
    }

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

    function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address);
}
