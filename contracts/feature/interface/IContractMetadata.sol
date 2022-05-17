// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    event ContractURIUpdated(string prevURI, string newURI);
}
