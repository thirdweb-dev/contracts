// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/IPlatformFee.sol";

/**
 *  @author  thirdweb.com
 */
library PlatformFeeStorage {
    bytes32 public constant PLATFORM_FEE_STORAGE_POSITION = keccak256("platform.fee.storage");

    struct Data {
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
        /// @dev The flat amount collected by the contract as fees on primary sales.
        uint256 flatPlatformFee;
        /// @dev Fee type variants: percentage fee and flat fee
        IPlatformFee.PlatformFeeType platformFeeType;
    }

    function platformFeeStorage() internal pure returns (Data storage platformFeeData) {
        bytes32 position = PLATFORM_FEE_STORAGE_POSITION;
        assembly {
            platformFeeData.slot := position
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
        PlatformFeeStorage.Data storage data = PlatformFeeStorage.platformFeeStorage();
        return (data.platformFeeRecipient, uint16(data.platformFeeBps));
    }

    /// @dev Returns the platform fee bps and recipient.
    function getFlatPlatformFeeInfo() public view returns (address, uint256) {
        PlatformFeeStorage.Data storage data = PlatformFeeStorage.platformFeeStorage();
        return (data.platformFeeRecipient, data.flatPlatformFee);
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeType() public view returns (PlatformFeeType) {
        return PlatformFeeStorage.platformFeeStorage().platformFeeType;
    }

    /// @notice Lets a module admin set platform fee type.
    function setPlatformFeeType(PlatformFeeType _feeType) external {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        _setupPlatformFeeType(_feeType);
    }

    /// @notice Lets a module admin set a flat fee on primary sales.
    function setFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) external {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }

        _setupFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);
    }

    /// @notice Updates the platform fee recipient and bps.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external override {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Sets platform fee type.
    function _setupPlatformFeeType(PlatformFeeType _feeType) internal {
        PlatformFeeStorage.platformFeeStorage().platformFeeType = _feeType;

        emit PlatformFeeTypeUpdated(_feeType);
    }

    /// @dev Sets a flat fee on primary sales.
    function _setupFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) internal {
        PlatformFeeStorage.platformFeeStorage().flatPlatformFee = _flatFee;
        PlatformFeeStorage.platformFeeStorage().platformFeeRecipient = _platformFeeRecipient;

        emit FlatPlatformFeeUpdated(_platformFeeRecipient, _flatFee);
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
