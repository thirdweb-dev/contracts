// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TWRouter.sol";

contract RouterImmutable is TWRouter {
    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _pluginRegistry, string[] memory _pluginNames) TWRouter(_pluginRegistry, _pluginNames) {}

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal pure override returns (bool) {
        return false;
    }
}
