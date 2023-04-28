// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils

import "../utils/BaseRouter.sol";
import "../../extension/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../dynamic-contracts/extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Interface
import "../interfaces/IAccountFactory.sol";

// Smart wallet implementation
import "../utils/AccountExtension.sol";
import { ManagedAccount, IEntryPoint } from "./ManagedAccount.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract ManagedAccountFactory is IAccountFactory, Multicall, PermissionsEnumerable, BaseRouter {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    ManagedAccount private immutable _accountImplementation;

    mapping(address => address) private accountAdmin;
    mapping(address => EnumerableSet.AddressSet) private accountsOfSigner;
    mapping(address => EnumerableSet.AddressSet) private signersOfAccount;

    address public immutable defaultExtension;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint) {
        defaultExtension = address(new AccountExtension(address(_entrypoint), address(this)));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _accountImplementation = new ManagedAccount(_entrypoint);
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new Account for admin.
    function createAccount(address _admin) external returns (address) {
        address impl = address(_accountImplementation);
        bytes32 salt = keccak256(abi.encode(_admin));
        address account = Clones.predictDeterministicAddress(impl, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, salt);

        ManagedAccount(payable(account)).initialize(_admin);

        accountAdmin[account] = _admin;

        emit AccountCreated(account, _admin);

        return account;
    }

    /// @notice Callback function for an Account to register its signers.
    function addSigner(address _signer) external {
        address account = msg.sender;
        require(accountAdmin[account] != address(0), "AccountFactory: invalid caller.");

        accountsOfSigner[_signer].add(account);
        signersOfAccount[account].add(_signer);

        emit SignerAdded(account, _signer);
    }

    /// @notice Callback function for an Account to un-register its signers.
    function removeSigner(address _signer) external {
        address account = msg.sender;
        require(accountAdmin[account] != address(0), "AccountFactory: invalid caller.");

        accountsOfSigner[_signer].remove(account);
        signersOfAccount[account].remove(_signer);

        emit SignerRemoved(account, _signer);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the implementation of the Account.
    function accountImplementation() external view override returns (address) {
        return address(_accountImplementation);
    }

    /// @notice Returns the address of an Account that would be deployed with the given admin signer.
    function getAddress(address _adminSigner) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(_adminSigner));
        return Clones.predictDeterministicAddress(address(_accountImplementation), salt);
    }

    /// @notice Returns the admin and all signers of an account.
    function getSignersOfAccount(address account) external view returns (address admin, address[] memory signers) {
        return (accountAdmin[account], signersOfAccount[account].values());
    }

    /// @notice Returns all accounts that the given address is a signer of.
    function getAccountsOfSigner(address signer) external view returns (address[] memory accounts) {
        return accountsOfSigner[signer].values();
    }

    /// @dev Returns the extension implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector) public view override returns (address) {
        address impl = getExtensionForFunction(_functionSelector).implementation;
        return impl != address(0) ? impl : defaultExtension;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    function _canSetExtension() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
