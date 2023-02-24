// SPDX-License-Identifier: Apache-2.0
// thirdweb Contract

pragma solidity ^0.8.0;

import "./TWRouter.sol";

contract RouterImmutable is TWRouter {
    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _extensionRegistry, string[] memory _extensionNames)
        TWRouter(_extensionRegistry, _extensionNames)
    {}

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetExtension() internal pure override returns (bool) {
        return false;
    }
}
