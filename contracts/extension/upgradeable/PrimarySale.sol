// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPrimarySale.sol";

library PrimarySaleStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant PRIMARY_SALE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("primary.sale.storage")) - 1)) & ~bytes32(uint256(0xff));

    struct Data {
        address recipient;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = PRIMARY_SALE_STORAGE_POSITION;
        assembly {
            data_.slot := position
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
        return _primarySaleStorage().recipient;
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
        if (_saleRecipient == address(0)) {
            revert("Invalid recipient");
        }
        _primarySaleStorage().recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Returns the PrimarySale storage.
    function _primarySaleStorage() internal pure returns (PrimarySaleStorage.Data storage data) {
        data = PrimarySaleStorage.data();
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual returns (bool);
}
