// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/upgradeable/Royalty.sol";
import "../../extension/upgradeable/ERC2771ContextConsumer.sol";
import "../../extension/interface/IPermissions.sol";

contract RoyaltyExt is Royalty, ERC2771ContextConsumer {
    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        // Check: default admin role
        try IPermissions(address(this)).hasRole(0x00, _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }
}
