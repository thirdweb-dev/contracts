// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

library ModularAccountStorage {
    /// @custom:storage-location erc7201:modular.account.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("modular.account.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant MODULAR_ACCOUNT_STORAGE_POSITION =
        0x858d12b8662f5371f269308912750e6d1d8e3f2e07a9479e78bb47537cfdf800;

    struct Data {
        address factory;
        address entrypointContract;
        address validator;
        bytes32 creationSalt;
    }

    function data() internal pure returns (Data storage modularAccountData) {
        bytes32 position = MODULAR_ACCOUNT_STORAGE_POSITION;
        assembly {
            modularAccountData.slot := position
        }
    }
}
