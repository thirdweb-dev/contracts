// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

library ReentrancyGuardStorage {
    /// @custom:storage-location erc7201:reentrancy.guard.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("reentrancy.guard.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant REENTRANCY_GUARD_STORAGE_POSITION =
        0x1d281c488dae143b6ea4122e80c65059929950b9c32f17fc57be22089d9c3b00;

    struct Data {
        uint256 _status;
    }

    function reentrancyGuardStorage() internal pure returns (Data storage reentrancyGuardData) {
        bytes32 position = REENTRANCY_GUARD_STORAGE_POSITION;
        assembly {
            reentrancyGuardData.slot := position
        }
    }
}
