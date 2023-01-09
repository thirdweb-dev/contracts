// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PlatformFeeStorage.sol";
import "../../extension/interface/IPlatformFee.sol";

/**
 *  @title   Platform Fee
 *  @notice  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about platform fees, if desired.
 */

abstract contract PlatformFeeLogic is IPlatformFee {
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() public view override returns (address, uint16) {
        PlatformFeeStorage.Data storage data = PlatformFeeStorage.platformFeeStorage();
        return (data.platformFeeRecipient, uint16(data.platformFeeBps));
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
        PlatformFeeStorage.Data storage data = PlatformFeeStorage.platformFeeStorage();
        if (_platformFeeBps > 10_000) {
            revert("Exceeds max bps");
        }

        data.platformFeeBps = uint16(_platformFeeBps);
        data.platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view virtual returns (bool);
}
