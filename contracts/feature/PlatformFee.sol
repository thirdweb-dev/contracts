// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IPlatformFee.sol";

abstract contract PlatformFee is IPlatformFee {
    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 private platformFeeBps;

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() public view override returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external override {
        require(_canSetPlatformFeeInfo(), "Not authorized");
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function _setupPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) internal {
        require(_platformFeeBps <= 10_000, "Exceeds max bps");

        platformFeeBps = uint16(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal virtual returns (bool);
}
