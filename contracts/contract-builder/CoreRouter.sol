// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouterWithDefaults.sol";

import "../extension/upgradeable/ContractMetadata.sol";
import "../extension/upgradeable/Ownable.sol";
import "../extension/upgradeable/Initializable.sol";
import "../extension/upgradeable/ERC2771ContextConsumer.sol";

abstract contract CoreRouter is
    Initializable,
    ContractMetadata,
    Ownable,
    ERC2771ContextConsumer,
    BaseRouterWithDefaults
{
    // Default extensions: enabled.
    constructor(Extension[] memory _defaultExtensions) BaseRouterWithDefaults(_defaultExtensions) {
        _disableInitializers();
    }
}
