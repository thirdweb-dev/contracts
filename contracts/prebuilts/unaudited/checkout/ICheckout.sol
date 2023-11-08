// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ICheckout {
    function createVault(address _vaultAdmin, bytes32 _salt) external payable returns (address);

    function createExecutor(address _executorAdmin, bytes32 _salt) external payable returns (address);
}
