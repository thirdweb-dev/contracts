// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IThirdwebContract.sol";

interface IThirdwebPlatformFee is IThirdwebContract {
    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address platformFeeRecipient, uint16 platformFeeBps);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;
}
