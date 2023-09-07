// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/upgradeable/PrimarySale.sol";
import "../../extension/upgradeable/ERC2771ContextConsumer.sol";
import "../../extension/interface/IPermissions.sol";

contract PrimarySaleExt is PrimarySale, ERC2771ContextConsumer {
    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        // Check: default admin role
        try IPermissions(address(this)).hasRole(0x00, _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }
}
