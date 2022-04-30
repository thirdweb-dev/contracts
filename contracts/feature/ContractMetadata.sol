// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interfaces/IThirdwebContract.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

abstract contract ContractMetadata is IThirdwebContract, AccessControlEnumerableUpgradeable {
    
    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }
}