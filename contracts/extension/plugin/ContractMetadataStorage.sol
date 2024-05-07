// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  @author  thirdweb.com
 */
library ContractMetadataStorage {
    /// @custom:storage-location erc7201:contract.metadata.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("contract.metadata.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant CONTRACT_METADATA_STORAGE_POSITION =
        0x4bc804ba64359c0e35e5ed5d90ee596ecaa49a3a930ddcb1470ea0dd625da900;

    struct Data {
        string contractURI;
    }

    function contractMetadataStorage() internal pure returns (Data storage contractMetadataData) {
        bytes32 position = CONTRACT_METADATA_STORAGE_POSITION;
        assembly {
            contractMetadataData.slot := position
        }
    }
}
