// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

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
    }

    function platformFeeStorage() internal pure returns (Data storage platformFeeData) {
        bytes32 position = PLATFORM_FEE_STORAGE_POSITION;
        assembly {
            platformFeeData.slot := position
        }
    }
}
