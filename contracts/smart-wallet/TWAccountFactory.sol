// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./TWAccount.sol";

/**
 *  TWAccountFactory capabilities:
 *  - deploy a clone pointing to a TWAccount implementation.
 */
contract TWAccountFactory is Multicall {
    TWAccount public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new TWAccount(_entryPoint);
    }

    /// @notice Deploys a new Account with the given salt and initialization data.
    function createAccount(bytes32 _salt, bytes calldata _initData) external returns (address account) {
        address impl = address(accountImplementation);
        account = Clones.cloneDeterministic(impl, _salt);

        // TODO: Emit event

        if (_initData.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(account, _initData);
        }
    }

    /// @notice Returns the address of an Account that would be deployed with the given salt.
    function getAddress(bytes32 _salt) external view returns (address) {
        return Clones.predictDeterministicAddress(address(accountImplementation), _salt);
    }
}
