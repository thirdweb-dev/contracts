// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../interfaces/ITWMultichainRegistry.sol";

library TWMultichainRegistryStorage {
    bytes32 public constant MULTICHAIN_REGISTRY_STORAGE_POSITION = keccak256("multichain.registry.storage");

    struct Data {
        /// @dev wallet address => [contract addresses]
        mapping(address => mapping(uint256 => EnumerableSet.AddressSet)) deployments;
        /// @dev contract address deployed => imported metadata uri
        mapping(uint256 => mapping(address => string)) addressToMetadataUri;
        EnumerableSet.UintSet chainIds;
    }

    function multichainRegistryStorage() internal pure returns (Data storage multichainRegistryData) {
        bytes32 position = MULTICHAIN_REGISTRY_STORAGE_POSITION;
        assembly {
            multichainRegistryData.slot := position
        }
    }
}
