// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/IPrimarySale.sol";

library PrimarySaleStorage {
    bytes32 public constant PRIMARY_SALE_STORAGE_POSITION = keccak256("primary.sale.storage");

    struct Data {
        address recipient;
    }

    function primarySaleStorage() internal pure returns (Data storage primarySaleData) {
        bytes32 position = PRIMARY_SALE_STORAGE_POSITION;
        assembly {
            primarySaleData.slot := position
        }
    }
}

/**
 *  @title   Primary Sale
 *  @notice  Thirdweb's `PrimarySale` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of primary sales, and lets the inheriting contract perform conditional logic that uses information about
 *           primary sales, if desired.
 */

abstract contract PrimarySale is IPrimarySale {
    /// @dev Returns primary sale recipient address.
    function primarySaleRecipient() public view override returns (address) {
        PrimarySaleStorage.Data storage data = PrimarySaleStorage.primarySaleStorage();
        return data.recipient;
    }

    /**
     *  @notice         Updates primary sale recipient.
     *  @dev            Caller should be authorized to set primary sales info.
     *                  See {_canSetPrimarySaleRecipient}.
     *                  Emits {PrimarySaleRecipientUpdated Event}; See {_setupPrimarySaleRecipient}.
     *
     *  @param _saleRecipient   Address to be set as new recipient of primary sales.
     */
    function setPrimarySaleRecipient(address _saleRecipient) external override {
        if (!_canSetPrimarySaleRecipient()) {
            revert("Not authorized");
        }
        _setupPrimarySaleRecipient(_saleRecipient);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function _setupPrimarySaleRecipient(address _saleRecipient) internal {
        PrimarySaleStorage.Data storage data = PrimarySaleStorage.primarySaleStorage();
        data.recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual returns (bool);
}
