// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPlatformFee.sol";

/**
 *  @author  thirdweb.com
 */
library PlatformFeeStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant PLATFORM_FEE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("platform.fee.storage")) - 1));

    struct Data {
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = PLATFORM_FEE_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

/**
 *  @author  thirdweb.com
 *
 *  @title   Platform Fee
 *  @notice  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about platform fees, if desired.
 */

abstract contract PlatformFee is IPlatformFee {
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() public view override returns (address, uint16) {
        return (_platformFeeStorage().platformFeeRecipient, uint16(_platformFeeStorage().platformFeeBps));
    }

    /**
     *  @notice         Updates the platform fee recipient and bps.
     *  @dev            Caller should be authorized to set platform fee info.
     *                  See {_canSetPlatformFeeInfo}.
     *                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.
     *
     *  @param _platformFeeRecipient   Address to be set as new platformFeeRecipient.
     *  @param _platformFeeBps         Updated platformFeeBps.
     */
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external override {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function _setupPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) internal {
        if (_platformFeeBps > 10_000) {
            revert("Exceeds max bps");
        }

        _platformFeeStorage().platformFeeBps = uint16(_platformFeeBps);
        _platformFeeStorage().platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Returns the PlatformFee storage.
    function _platformFeeStorage() internal pure returns (PlatformFeeStorage.Data storage data) {
        data = PlatformFeeStorage.data();
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view virtual returns (bool);
}
