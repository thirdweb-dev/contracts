// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../inherit/Royalty.sol";
import "../inherit/ERC2771ContextConsumer.sol";
import "../inherit/internal/PermissionsInternal.sol";

import "../../extension/upgradeable/PlatformFee.sol";
import "../../extension/upgradeable/PrimarySale.sol";

contract FeeManagerExt is PlatformFee, PrimarySale, Royalty, ERC2771ContextConsumer, PermissionsInternal {
    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        // Check: default admin role
        return _hasRole(0x00, _msgSender());
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view virtual override returns (bool) {
        // Check: default admin role
        return _hasRole(0x00, _msgSender());
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return _hasRole(0x00, _msgSender());
    }
}
