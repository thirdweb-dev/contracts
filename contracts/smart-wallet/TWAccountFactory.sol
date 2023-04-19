// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "../extension/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../lib/TWStringSet.sol";

// Interface
import "./interfaces/ITWAccountFactory.sol";

// Smart wallet implementation
import "./TWAccount.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

/*///////////////////////////////////////////////////////////////
                            Storage layout
//////////////////////////////////////////////////////////////*/

library TWAccountFactoryStorage {
    bytes32 internal constant TWACCOUNT_FACTORY_STORAGE_POSITION = keccak256("twaccount.factory.storage");

    struct Data {
        TWStringSet.Set allAccounts;
        mapping(address => TWStringSet.Set) accountsOfSigner;
    }

    function factoryStorage() internal pure returns (Data storage twaccountFactoryData) {
        bytes32 position = TWACCOUNT_FACTORY_STORAGE_POSITION;
        assembly {
            twaccountFactoryData.slot := position
        }
    }
}

contract TWAccountFactory is ITWAccountFactory, Multicall {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    TWAccount private immutable _accountImplementation;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint) {
        _accountImplementation = new TWAccount(_entrypoint);
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new Account with the given admin and accountId used as salt.
    function createAccount(address _admin, string memory _accountId) external returns (address) {
        address impl = address(_accountImplementation);
        bytes32 salt = keccak256(abi.encode(_accountId));
        address account = Clones.predictDeterministicAddress(impl, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, salt);

        TWAccount(payable(account)).initialize(_admin);

        _setupAccount(_admin, _accountId);

        emit AccountCreated(account, _admin, _accountId);

        return account;
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the implementation of the Account.
    function accountImplementation() external view override returns (address) {
        return address(_accountImplementation);
    }

    /// @notice Returns the address of an Account that would be deployed with the given accountId as salt.
    function getAddress(string memory _accountId) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(_accountId));
        return Clones.predictDeterministicAddress(address(_accountImplementation), salt);
    }

    /// @notice Returns the list of accounts created by a signer.
    function getAccountsOfSigner(address _signer) external view returns (AccountInfo[] memory) {
        TWAccountFactoryStorage.Data storage data = TWAccountFactoryStorage.factoryStorage();
        return _formatAccounts(data.accountsOfSigner[_signer].values());
    }

    /// @notice Returns the list of all accounts.
    function getAllAccounts() external view returns (AccountInfo[] memory accounts) {
        TWAccountFactoryStorage.Data storage data = TWAccountFactoryStorage.factoryStorage();
        return _formatAccounts(data.allAccounts.values());
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Formats a list of accountIds to a list of `AccountInfo` (account id + account address).
    function _formatAccounts(string[] memory _accountIds) internal view returns (AccountInfo[] memory accounts) {
        uint256 len = _accountIds.length;
        accounts = new AccountInfo[](len);
        for (uint256 i = 0; i < len; i += 1) {
            string memory accountId = _accountIds[i];
            address account = getAddress(accountId);
            accounts[i] = AccountInfo(accountId, account);
        }
    }

    /// @dev Adds an account to the list of accounts created by a signer.
    function _setupAccount(address _signer, string memory _accountId) internal {
        TWAccountFactoryStorage.Data storage data = TWAccountFactoryStorage.factoryStorage();
        data.allAccounts.add(_accountId);
        data.accountsOfSigner[_signer].add(_accountId);
    }
}
