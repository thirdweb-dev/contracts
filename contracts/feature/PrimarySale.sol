// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IPrimarySale.sol";

abstract contract PrimarySale is IPrimarySale {
    /// @dev The address that receives all primary sales value.
    address private recipient;

    function primarySaleRecipient() public view override returns (address) {
        return recipient;
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) public override {
        require(_canSetPrimarySaleRecipient(), "Not authorized");

        recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal virtual returns (bool);
}
