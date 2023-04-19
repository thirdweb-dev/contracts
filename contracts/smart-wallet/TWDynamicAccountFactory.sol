// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "../extension/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// Interface
import "./interfaces/ITWAccountFactory.sol";

// Smart wallet implementation
import "./TWDynamicAccount.sol";

contract TWDynamicAccountFactory is ITWAccountFactory, Multicall {
    TWDynamicAccount private immutable _accountImplementation;

    constructor(IEntryPoint _entrypoint) {
        _accountImplementation = new TWDynamicAccount(_entrypoint);
    }

    /// @notice Returns the implementation of the Account.
    function accountImplementation() external view override returns (address) {
        return address(_accountImplementation);
    }

    /// @notice Deploys a new Account with the given admin and accountId used as salt.
    function createAccount(address _admin, bytes32 _accountId) external returns (address) {
        address impl = address(_accountImplementation);
        address account = Clones.predictDeterministicAddress(impl, _accountId);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, _accountId);

        TWAccount(payable(account)).initialize(_admin);

        emit AccountCreated(account, _admin, _accountId);

        return account;
    }

    /// @notice Returns the address of an Account that would be deployed with the given accountId as salt.
    function getAddress(bytes32 _accountId) external view returns (address) {
        return Clones.predictDeterministicAddress(address(_accountImplementation), _accountId);
    }
}
