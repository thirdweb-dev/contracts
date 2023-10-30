// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../../external-deps/openzeppelin/utils/structs/EnumerableSet.sol";

library BaseAccountFactoryStorage {
    /// @custom:storage-location erc7201:base.account.factory.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("base.account.factory.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant BASE_ACCOUNT_FACTORY_STORAGE_POSITION =
        0x82f5b3e5f5ca1c04b70bced106a2c3b72d9cb53ebbafb3cad0740983db742900;

    struct Data {
        EnumerableSet.AddressSet allAccounts;
        mapping(address => EnumerableSet.AddressSet) accountsOfSigner;
    }

    function data() internal pure returns (Data storage baseAccountFactoryData) {
        bytes32 position = BASE_ACCOUNT_FACTORY_STORAGE_POSITION;
        assembly {
            baseAccountFactoryData.slot := position
        }
    }
}
