// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPlatformFee.sol";

/**
 *  @author  thirdweb.com
 */
library PlatformFeeStorage {
    /// @custom:storage-location erc7201:platform.fee.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("platform.fee.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant PLATFORM_FEE_STORAGE_POSITION =
        0xc0c34308b4a2f4c5ee9af8ba82541cfb3c33b076d1fd05c65f9ce7060c64c400;

    struct Data {
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
        /// @dev Fee type variants: percentage fee and flat fee
        IPlatformFee.PlatformFeeType platformFeeType;
        /// @dev The flat amount collected by the contract as fees on primary sales.
        uint256 flatPlatformFee;
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

    /// @dev Returns the platform fee bps and recipient.
    function getFlatPlatformFeeInfo() public view returns (address, uint256) {
        return (_platformFeeStorage().platformFeeRecipient, _platformFeeStorage().flatPlatformFee);
    }

    /// @dev Returns the platform fee type.
    function getPlatformFeeType() public view returns (PlatformFeeType) {
        return _platformFeeStorage().platformFeeType;
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
        if (_platformFeeRecipient == address(0)) {
            revert("Invalid recipient");
        }

        _platformFeeStorage().platformFeeBps = uint16(_platformFeeBps);
        _platformFeeStorage().platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @notice Lets a module admin set a flat fee on primary sales.
    function setFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) external {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }

        _setupFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);
    }

    /// @dev Sets a flat fee on primary sales.
    function _setupFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) internal {
        _platformFeeStorage().flatPlatformFee = _flatFee;
        _platformFeeStorage().platformFeeRecipient = _platformFeeRecipient;

        emit FlatPlatformFeeUpdated(_platformFeeRecipient, _flatFee);
    }

    /// @notice Lets a module admin set platform fee type.
    function setPlatformFeeType(PlatformFeeType _feeType) external {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        _setupPlatformFeeType(_feeType);
    }

    /// @dev Sets platform fee type.
    function _setupPlatformFeeType(PlatformFeeType _feeType) internal {
        _platformFeeStorage().platformFeeType = _feeType;

        emit PlatformFeeTypeUpdated(_feeType);
    }

    /// @dev Returns the PlatformFee storage.
    function _platformFeeStorage() internal pure returns (PlatformFeeStorage.Data storage data) {
        data = PlatformFeeStorage.data();
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view virtual returns (bool);
}
