// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./ICheckout.sol";
import "./Vault.sol";
import "./Executor.sol";

import "../../../external-deps/openzeppelin/utils/Create2.sol";

import "../../../extension/PermissionsEnumerable.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract Checkout is PermissionsEnumerable, ICheckout {
    /// @dev Registry of vaults created through this Checkout
    mapping(address => bool) isVaultRegistered;

    /// @dev Registry of executors created through this Checkout
    mapping(address => bool) isExecutorRegistered;

    address public immutable vaultImplementation;
    address public immutable executorImplementation;

    constructor(
        address _defaultAdmin,
        address _vaultImplementation,
        address _executorImplementation
    ) {
        vaultImplementation = _vaultImplementation;
        executorImplementation = _executorImplementation;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    function createVault(address _vaultAdmin, bytes32 _salt) external payable returns (address) {
        bytes32 salthash = keccak256(abi.encodePacked(msg.sender, _salt));
        address vault = Clones.cloneDeterministic(vaultImplementation, salthash);

        (bool success, ) = vault.call(abi.encodeWithSelector(Vault.initialize.selector, _vaultAdmin));

        require(success, "Deployment failed");

        isVaultRegistered[vault] = true;

        return vault;
    }

    function createExecutor(address _executorAdmin, bytes32 _salt) external payable returns (address) {
        bytes32 salthash = keccak256(abi.encodePacked(msg.sender, _salt));
        address executor = Clones.cloneDeterministic(executorImplementation, salthash);

        (bool success, ) = executor.call(abi.encodeWithSelector(Executor.initialize.selector, _executorAdmin));

        require(success, "Deployment failed");

        isExecutorRegistered[executor] = true;

        return executor;
    }

    function authorizeVaultToExecutor(address _vault, address _executor) external {
        require(IVault(_vault).canAuthorizeVaultToExecutor(msg.sender), "Not authorized");
        require(isExecutorRegistered[_executor], "Executor not found");

        IVault(_vault).setExecutor(_executor);
    }
}
