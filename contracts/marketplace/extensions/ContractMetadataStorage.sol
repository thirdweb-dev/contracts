// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../extension/interface/IContractMetadata.sol";

library ContractMetadataStorage {
    bytes32 public constant CONTRACT_METADATA_STORAGE_POSITION = keccak256("contract.metadata.storage");

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
