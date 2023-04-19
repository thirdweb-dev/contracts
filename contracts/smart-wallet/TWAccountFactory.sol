// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "../extension/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Interface
import "./interfaces/ITWAccountFactory.sol";

// Smart wallet implementation
import "./TWAccount.sol";

library TWAccountFactoryStorage {
    bytes32 internal constant TWACCOUNT_FACTORY_STORAGE_POSITION = keccak256("twaccount.factory.storage");

    struct Data {
        mapping(address => EnumerableSet.AddressSet) accountsOfSigner;
    }

    function factoryStorage() internal pure returns (Data storage twaccountFactoryData) {
        bytes32 position = TWACCOUNT_FACTORY_STORAGE_POSITION;
        assembly {
            twaccountFactoryData.slot := position
        }
    }
}

contract TWAccountFactory is ITWAccountFactory, Multicall {
    using EnumerableSet for EnumerableSet.AddressSet;

    TWAccount private immutable _accountImplementation;

    constructor(IEntryPoint _entrypoint) {
        _accountImplementation = new TWAccount(_entrypoint);
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

        _addAccount(_admin, account);

        emit AccountCreated(account, _admin, _accountId);

        return account;
    }

    /// @notice Returns the address of an Account that would be deployed with the given accountId as salt.
    function getAddress(bytes32 _accountId) external view returns (address) {
        return Clones.predictDeterministicAddress(address(_accountImplementation), _accountId);
    }

    /// @notice Returns the list of accounts created by a signer.
    function getAccountsOfSigner(address _signer) external view returns (address[] memory allAccounts) {
        TWAccountFactoryStorage.Data storage data = TWAccountFactoryStorage.factoryStorage();
        return data.accountsOfSigner[_signer].values();
    }

    /// @dev Adds an account to the list of accounts created by a signer.
    function _addAccount(address _signer, address _account) internal {
        TWAccountFactoryStorage.Data storage data = TWAccountFactoryStorage.factoryStorage();
        data.accountsOfSigner[_signer].add(_account);
    }
}
