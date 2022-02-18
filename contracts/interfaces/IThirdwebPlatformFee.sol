// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IThirdwebPlatformFee {
    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address platformFeeRecipient, uint16 platformFeeBps);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;
}
