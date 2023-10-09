// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

library AccountCoreStorage {
    /// @custom:storage-location erc7201:account.core.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("account.core.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ACCOUNT_CORE_STORAGE_POSITION =
        0x036f52c1827dab135f7fd44ca0bddde297e2f659c710e0ec53e975f22b548300;

    struct Data {
        address entrypointOverride;
        address firstAdmin;
    }

    function data() internal pure returns (Data storage acountCoreData) {
        bytes32 position = ACCOUNT_CORE_STORAGE_POSITION;
        assembly {
            acountCoreData.slot := position
        }
    }
}
