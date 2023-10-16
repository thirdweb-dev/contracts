// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about platform fees, if desired.
 */

interface IPlatformFee {
    /// @dev Fee type variants: percentage fee and flat fee
    enum PlatformFeeType {
        Bps,
        Flat
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Emitted when the flat platform fee is updated.
    event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee);

    /// @dev Emitted when the platform fee type is updated.
    event PlatformFeeTypeUpdated(PlatformFeeType feeType);
}
