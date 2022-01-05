// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IThirdwebModule {
    /// @dev Returns the module type of the contract.
    function moduleType() external view returns (bytes32);
}