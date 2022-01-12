// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IThirdwebModule {

    /// @dev Emitted when a new owner is set.
    event NewOwner(address prevOwner, address newOwner);

    /// @dev Returns the module type of the contract.
    function moduleType() external view returns (bytes32);

    /// @dev Returns the version of the contract.
    function version() external view returns (uint256);
}