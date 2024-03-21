// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ICheckout {
    /// @dev Emitted when an executor is authorized to use funds from the given vault.
    event VaultAuthorizedToExecutor(address _vault, address _executor);

    /// @dev Emitted when a new Executor contract is deployed.
    event ExecutorCreated(address _executor, address _defaultAdmin);

    /// @dev Emitted when a new Vault contrac is deployed.
    event VaultCreated(address _vault, address _defaultAdmin);

    function createVault(address _vaultAdmin, bytes32 _salt) external payable returns (address);

    function createExecutor(address _executorAdmin, bytes32 _salt) external payable returns (address);

    function authorizeVaultToExecutor(address _vault, address _executor) external;
}
