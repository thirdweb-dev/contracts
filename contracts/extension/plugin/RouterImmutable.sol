// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IMap.sol";
import "../../extension/Multicall.sol";
import "../../eip/ERC165.sol";
import "./Map.sol";
import "./Router.sol";

contract RouterImmutable is Router {
    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _functionMap) Router(_functionMap) {}

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal pure override returns (bool) {
        return false;
    }
}
