// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { PrimarySaleStorage } from "../PrimarySale.sol";

contract PrimarySaleInit {
    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function _setupPrimarySaleRecipient(address _saleRecipient) internal {
        PrimarySaleStorage.Data storage data = PrimarySaleStorage.data();
        data.recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }
}
