// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ITWAccountFactory {
    event AccountCreated(address indexed account, address indexed accountAdmin);

    /// @notice Returns the address of the Account implementation.
    function accountImplementation() external view returns (address);

    /// @notice Deploys a new Account with the given admin and salt.
    function createAccount(address admin, bytes32 salt) external returns (address account);

    /// @notice Returns the address of an Account that would be deployed with the given salt.
    function getAddress(bytes32 salt) external view returns (address);
}
