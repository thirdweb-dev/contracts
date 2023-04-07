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

    /// @notice Deploys a new Account with the given admin and salt.
    function createAccount(address _admin, bytes32 _salt) external returns (address account) {
        address impl = address(_accountImplementation);
        account = Clones.cloneDeterministic(impl, _salt);

        TWAccount(account).initialize(_admin);

        emit AccountCreated(account, _admin);
    }

    /// @notice Returns the address of an Account that would be deployed with the given salt.
    function getAddress(bytes32 _salt) external view returns (address) {
        return Clones.predictDeterministicAddress(address(_accountImplementation), _salt);
    }
}
