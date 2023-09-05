// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouterWithDefaults.sol";
import "../extension/upgradeable/ContractMetadata.sol";
import "../extension/upgradeable/Ownable.sol";
import "../extension/upgradeable/ERC2771ContextConsumer.sol";

contract CoreRouterWithDefaults is ContractMetadata, Ownable, ERC2771ContextConsumer, BaseRouterWithDefaults {
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    // Default extensions: enabled.
    constructor(address _defaultOwner, Extension[] memory _defaultExtensions)
        BaseRouterWithDefaults(_defaultExtensions)
    {
        _setupOwner(_defaultOwner);
    }

    /*///////////////////////////////////////////////////////////////
                        Override: Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension(Extension memory) internal view virtual override returns (bool) {
        return _msgSender() == owner();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return _msgSender() == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return _msgSender() == owner();
    }
}
