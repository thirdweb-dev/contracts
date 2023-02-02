// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Router.sol";

contract RouterImmutable is Router {
    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _pluginRegistry, string[] memory _pluginNames) Router(_pluginRegistry, _pluginNames) {}

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal pure override returns (bool) {
        return false;
    }
}
