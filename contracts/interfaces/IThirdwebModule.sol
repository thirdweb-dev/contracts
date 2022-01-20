// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IThirdwebModule {

    /// @dev Returns the module type of the contract.
    function moduleType() external view returns (bytes32);

    /// @dev Returns the version of the contract.
    function version() external view returns (uint256);

    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    /// @dev Only module admin can call this function.
    function setContractURI(string calldata _URI) external;
}
