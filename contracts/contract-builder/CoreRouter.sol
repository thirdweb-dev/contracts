// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "lib/dynamic-contracts/src/presets/BaseRouter.sol";

// Core
import "lib/dynamic-contracts/src/core/Router.sol";

// Utils
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";
import "lib/dynamic-contracts/src/presets/utils/ExtensionState.sol";
import "./extension/PermissionOverride.sol";

// Fixed extensions
import "../extension/Ownable.sol";
import "../extension/ContractMetadata.sol";

contract CoreRouter is BaseRouter, ContractMetadata, Ownable {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        _setupOwner(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension(Extension memory) internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
