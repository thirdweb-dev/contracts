// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ITWAccountFactory {
    event AccountCreated(address indexed account, bytes32 salt);

    /// @notice Returns the address of the Account implementation.
    function accountImplementation() external view returns (address);

    /// @notice Deploys a new Account with the given salt and initialization data.
    function createAccount(bytes32 _salt, bytes calldata _initData) external returns (address account);

    /// @notice Returns the address of an Account that would be deployed with the given salt.
    function getAddress(bytes32 _salt) external view returns (address);
}
