// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library PlatformFeeStorage {
    bytes32 public constant PLATFORM_FEE_STORAGE_POSITION = keccak256("platform.fee.storage");

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
