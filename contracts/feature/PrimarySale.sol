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
    function setPrimarySaleRecipient(address _saleRecipient) external override {
        require(_canSetPrimarySaleRecipient(), "Not authorized");
        _setupPrimarySaleRecipient(_saleRecipient);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function _setupPrimarySaleRecipient(address _saleRecipient) internal {
        recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal virtual returns (bool);
}
