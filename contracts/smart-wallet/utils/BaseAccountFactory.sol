// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "../../extension/Multicall.sol";
import "../../openzeppelin-presets/proxy/Clones.sol";
import "../../openzeppelin-presets/utils/structs/EnumerableSet.sol";
import "../utils/BaseAccount.sol";
import "../../extension/interface/IAccountPermissions.sol";
import "../../lib/BytesLib.sol";

// Interface
import "../interfaces/IEntrypoint.sol";
import "../interfaces/IAccountFactory.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

abstract contract BaseAccountFactory is IAccountFactory, Multicall {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    address public immutable accountImplementation;
    address public immutable entrypoint;

    EnumerableSet.AddressSet private allAccounts;
    mapping(address => EnumerableSet.AddressSet) internal accountsOfSigner;
    mapping(address => EnumerableSet.AddressSet) internal signersOfAccount;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _accountImpl, address _entrypoint) {
        accountImplementation = _accountImpl;
        entrypoint = _entrypoint;
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new Account for admin.
    function createAccount(address _admin, bytes calldata _data) external virtual override returns (address) {
        address impl = accountImplementation;
        bytes32 salt = _generateSalt(_admin, _data);
        address account = Clones.predictDeterministicAddress(impl, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, salt);

        if (msg.sender != entrypoint) {
            require(allAccounts.add(account), "AccountFactory: account already registered");
        }

        _initializeAccount(account, _admin, _data);

        emit AccountCreated(account, _admin);

        return account;
    }

    /// @notice Callback function for an Account to register itself on the factory.
    function onRegister() external {
        address account = msg.sender;
        require(_isAccountOfFactory(account), "AccountFactory: not an account.");

        require(allAccounts.add(account), "AccountFactory: account already registered");
    }

    function onSignerAdded(address _signer) external {
        address account = msg.sender;
        require(_isAccountOfFactory(account), "AccountFactory: not an account.");

        bool isAdmin = IAccountPermissions(account).isAdmin(_signer);

        if (!isAdmin) {
            IAccountPermissions.RoleRestrictions memory restrictions = IAccountPermissions(account)
                .getRoleRestrictionsForAccount(_signer);
            require(
                restrictions.startTimestamp <= block.timestamp && block.timestamp < restrictions.endTimestamp,
                "AccountFactory: invalid signer."
            );
        }

        bool isNewAccount = accountsOfSigner[_signer].add(account);
        bool isNewSigner = signersOfAccount[account].add(_signer);

        if (!isNewAccount || !isNewSigner) {
            revert("AccountFactory: signer already added");
        }

        emit SignerAdded(account, _signer);
    }

    /// @notice Callback function for an Account to un-register its signers.
    function onSignerRemoved(address _signer) external {
        address account = msg.sender;
        require(_isAccountOfFactory(account), "AccountFactory: not an account.");

        bool isAccount = accountsOfSigner[_signer].remove(account);
        bool isSigner = signersOfAccount[account].remove(_signer);

        if (!isAccount || !isSigner) {
            revert("AccountFactory: signer not found");
        }

        emit SignerRemoved(account, _signer);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether an account is registered on this factory.
    function isRegistered(address _account) external view returns (bool) {
        return allAccounts.contains(_account);
    }

    /// @notice Returns all accounts created on the factory.
    function getAllAccounts() external view returns (address[] memory) {
        return allAccounts.values();
    }

    /// @notice Returns the address of an Account that would be deployed with the given admin signer.
    function getAddress(address _adminSigner, bytes calldata _data) public view returns (address) {
        bytes32 salt = _generateSalt(_adminSigner, _data);
        return Clones.predictDeterministicAddress(accountImplementation, salt);
    }

    /// @notice Returns all signers of an account.
    function getSignersOfAccount(address account) external view returns (address[] memory signers) {
        return signersOfAccount[account].values();
    }

    /// @notice Returns all accounts that the given address is a signer of.
    function getAccountsOfSigner(address signer) external view returns (address[] memory accounts) {
        return accountsOfSigner[signer].values();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether the caller is an account deployed by this factory.
    function _isAccountOfFactory(address _account) internal view virtual returns (bool) {
        address impl = _getImplementation(_account);
        return _account.code.length > 0 && impl == accountImplementation;
    }

    function _getImplementation(address cloneAddress) internal view returns (address) {
        bytes memory code = cloneAddress.code;
        return BytesLib.toAddress(code, 10);
    }

    /// @dev Returns the salt used when deploying an Account.
    function _generateSalt(address _admin, bytes calldata) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_admin));
    }

    /// @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
    function _initializeAccount(
        address _account,
        address _admin,
        bytes calldata _data
    ) internal virtual;
}
