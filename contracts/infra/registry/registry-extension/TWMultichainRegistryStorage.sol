// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../interface/ITWMultichainRegistry.sol";

library TWMultichainRegistryStorage {
    /// @custom:storage-location erc7201:multichain.registry.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("multichain.registry.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant MULTICHAIN_REGISTRY_STORAGE_POSITION =
        0x14e6df431852605a9ea88d8bd521d0d3fa06563ab37f65080e288e5afad4ac00;

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
