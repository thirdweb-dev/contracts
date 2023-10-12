// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "lib/dynamic-contracts/src/presets/BaseRouter.sol";

// Core
import "lib/dynamic-contracts/src/core/Router.sol";

// Utils
import "lib/dynamic-contracts/src/lib/StringSet.sol";
import "./extension/PermissionOverride.sol";

// Fixed extensions
import "../../../extension/Ownable.sol";
import "../../../extension/ContractMetadata.sol";

/**
 *   ////////////
 *
 *   NOTE: This contract is a work in progress, and has not been audited.
 *
 *   ////////////
 */

contract CoreRouter is BaseRouter, ContractMetadata, Ownable {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Extension[] memory _extensions) BaseRouter(_extensions) {
        // Initialize extensions
        __BaseRouter_init();

        _setupOwner(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
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
