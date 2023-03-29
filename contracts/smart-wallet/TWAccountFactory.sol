// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "../extension/Multicall.sol";

import "./interfaces/ITWAccountFactory.sol";

import "./TWAccountRouter.sol";

/**
 *  TWAccountFactory capabilities:
 *  - deploy a clone pointing to a TWAccount implementation.
 */
contract TWAccountFactory is ITWAccountFactory, Multicall {
    TWAccountRouter private immutable _accountImplementation;

    constructor(TWAccountRouter router) {
        _accountImplementation = router;
    }

    /// @notice Returns the implementation of the Account.
    function accountImplementation() external view override returns (address) {
        return address(_accountImplementation);
    }

    /// @notice Deploys a new Account with the given salt and initialization data.
    function createAccount(bytes32 _salt, bytes calldata _initData) external returns (address account) {
        address impl = address(_accountImplementation);
        account = Clones.cloneDeterministic(impl, _salt);

        emit AccountCreated(account, _salt);

        if (_initData.length > 0) {
            // slither-disable-next-line unused-return
            (bool success, bytes memory returndata) = account.call(_initData);
            TWAddress.verifyCallResult(success, returndata, "TWAccountFactory: failed to initialize account.");
        }
    }

    /// @notice Returns the address of an Account that would be deployed with the given salt.
    function getAddress(bytes32 _salt) external view returns (address) {
        return Clones.predictDeterministicAddress(address(_accountImplementation), _salt);
    }
}
