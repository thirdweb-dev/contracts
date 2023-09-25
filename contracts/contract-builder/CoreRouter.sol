// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouter.sol";

import { ContractMetadata } from "../extension/upgradeable/ContractMetadata.sol";
import { Ownable } from "../extension/upgradeable/Ownable.sol";
import { PermissionsEnumerable } from "./extension/PermissionsEnumerable.sol";
import { Initializable } from "../extension/upgradeable/Initializable.sol";
import { ERC2771Context } from "./extension/ERC2771Context.sol";
import { Multicall } from "../extension/Multicall.sol";

/**
 *  The `CoreRouter` contract is a router contract that starts with a basic set of fixed functions / functionality.
 *  The `CoreRouter` contract is initializable, and is meant to be used via a proxy contract pointing to it.
 *
 *  The `CoreRouter` contract has the following fixed functions / functionality:
 *  - ContractMetadata: setting and getting contract metadata
 *  - PermissionsEnumerable & Ownable: a permissions system for the contract
 *  - ERC2771Context & ERC2771ContextConsumer: gasless support
 */

contract CoreRouter is
    Initializable,
    Multicall,
    ContractMetadata,
    Ownable,
    PermissionsEnumerable,
    ERC2771Context,
    BaseRouter
{
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(Extension[] memory _defaultExtensions) BaseRouter(_defaultExtensions) {
        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev To override; returns whether all relevant permission and other checks are met before any upgrade.
    function isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return hasRole(keccak256("EXTENSION_ROLE"), _msgSender());
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        // Defualt admin role.
        return hasRole(0x00, _msgSender());
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        // Defualt admin role.
        return hasRole(0x00, _msgSender());
    }
}
