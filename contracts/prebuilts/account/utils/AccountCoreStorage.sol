// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

library AccountCoreStorage {
    bytes32 public constant ACCOUNT_CORE_STORAGE_POSITION = keccak256("account.core.storage");

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
