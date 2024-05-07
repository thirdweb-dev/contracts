// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ContractMetadataStorage } from "../ContractMetadata.sol";

contract ContractMetadataInit {
    event ContractURIUpdated(string prevURI, string newURI);

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        ContractMetadataStorage.Data storage data = ContractMetadataStorage.data();
        string memory prevURI = data.contractURI;
        data.contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }
}
