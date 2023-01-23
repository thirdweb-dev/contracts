// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

////////// Interfaces //////////
import "./interface/IAccountAdmin.sol";
import "./interface/IAccount.sol";

////////// Helpers //////////
import "./Account.sol";

////////// Utils //////////
import "../extension/Multicall.sol";
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

////////// NOTE(S) //////////
/**
 *  - One Signer can be a part of many Accounts.
 *  - One Account can have many Signers.
 *  - A Signer-AccountId pair hash can only be used/associated with one unique account.
 *    i.e. a Signer must use unique accountId for each Account it wants to be a part of.
 *
 *  - How does data fetching work?
 *      - Fetch all accounts for a single signer.
 *      - Fetch all signers for a single account.
 *      - Fetch the unique account for a signer-accountId pair.
 */

interface IAccountInitialize {
    function initialize(
        address[] memory trustedForwarders,
        address controller,
        address signer,
        bytes32 accountId
    ) external payable;
}

contract AccountAdmin is IAccountAdmin, Initializable, EIP712Upgradeable, ERC2771ContextUpgradeable, Multicall {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSAUpgradeable for bytes32;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    bytes32 private constant CREATE_TYPEHASH =
        keccak256(
            "CreateAccountParams(address signer,bytes32 accountId,bytes32 deploymentSalt,uint256 initialAccountBalance,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice Implementation address for `Account`.
    address public immutable accountImplementation;

    /// @notice Trusted forwarders for gasless transactions.
    address[] private trustedForwarders;

    /// @dev Signer => Accounts where signer is an actor.
    mapping(address => EnumerableSet.AddressSet) private signerToAccounts;

    /// @dev Account => Signers that are actors in account.
    mapping(address => EnumerableSet.AddressSet) private accountToSigners;

    /// @dev AccountId => Account.
    mapping(bytes32 => address) private idToAccount;

    /// @dev Address => whether the address is of an account created via this admin contract.
    mapping(address => bool) private isAssociatedAccount;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer
    //////////////////////////////////////////////////////////////*/

    constructor(address _accountImplementation) {
        accountImplementation = _accountImplementation;
    }

    function initialize(address[] memory _trustedForwarders) external initializer {
        __EIP712_init("thirdweb_wallet_admin", "1");
        __ERC2771Context_init(_trustedForwarders);

        uint256 len = _trustedForwarders.length;
        for (uint256 i = 0; i < len; i += 1) {
            trustedForwarders.push(_trustedForwarders[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether a request is processed within its respective valid time window.
    modifier onlyValidTimeWindow(uint128 validityStartTimestamp, uint128 validityEndTimestamp) {
        /// @validate: request to create account not pre-mature or expired.
        require(
            validityStartTimestamp <= block.timestamp && block.timestamp < validityEndTimestamp,
            "AccountAdmin: request premature or expired."
        );

        _;
    }

    /// @dev Checks whether the caller is an account created via this admin contract.
    modifier onlyAssociatedAccount() {
        require(isAssociatedAccount[_msgSender()], "AccountAdmin: caller not account of this admin.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Creating an account
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates an account for a (signer, accountId) pair.
    function createAccount(CreateAccountParams calldata _params, bytes calldata _signature)
        external
        payable
        onlyValidTimeWindow(_params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (address account)
    {
        /// @validate: accountId not empty.
        require(_params.accountId != bytes32(0), "AccountAdmin: invalid accountId.");
        /// @validate: sent initial account balance.
        require(_params.initialAccountBalance == msg.value, "AccountAdmin: incorrect value sent.");

        bytes32 messageHash = keccak256(
            abi.encode(
                CREATE_TYPEHASH,
                _params.signer,
                _params.accountId,
                _params.deploymentSalt,
                _params.initialAccountBalance,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        /// @validate: signature-of-intent from target signer.
        _validateSignature(messageHash, _signature, _params.signer);

        /// @validate: new accountId to set does not already have an associated account.
        require(idToAccount[_params.accountId] == address(0), "AccountAdmin: accountId already used.");

        /// @validate: (By Create2) No repeat deployment salt.
        bytes32 salt = keccak256(abi.encode(_params.deploymentSalt, _msgSender()));
        account = Clones.cloneDeterministic(accountImplementation, salt);
        IAccountInitialize(account).initialize{ value: _params.initialAccountBalance }(
            trustedForwarders,
            address(this),
            _params.signer,
            _params.accountId
        );

        isAssociatedAccount[account] = true;
        accountToSigners[account].add(_params.signer);
        signerToAccounts[_params.signer].add(account);
        idToAccount[_params.accountId] = account;

        emit AccountCreated(account, _params.signer, _msgSender(), _params.accountId);
        emit SignerAdded(_params.signer, account, _params.accountId);
    }

    /*///////////////////////////////////////////////////////////////
                Relaying transaction data to an account.
    //////////////////////////////////////////////////////////////*/

    /// @notice Calls an account with transaction data.
    function relay(
        address _signer,
        bytes32 _accountId,
        uint256 _value,
        uint256 _gas,
        bytes calldata _data
    ) external payable returns (bool, bytes memory) {
        require(_value == msg.value, "AccountAdmin: incorrect value sent.");

        address account = idToAccount[_accountId];

        /// @validate: account exists for given accountId.
        require(account != address(0), "AccountAdmin: no account with given accountId.");

        bool success;
        bytes memory result;
        if (_gas > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = account.call{ gas: _gas, value: _value }(_data);
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = account.call{ value: _value }(_data);
        }

        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert("Transaction reverted silently");
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
        // Check gas: https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > _gas / 63);

        emit CallResult(account, _signer, success);

        return (success, result);
    }

    /*///////////////////////////////////////////////////////////////
                Changing signer composition of accounts
    //////////////////////////////////////////////////////////////*/

    /// @notice Called by an account (itself) when a signer is added to it.
    function addSignerToAccount(address _signer, bytes32 _accountId) external onlyAssociatedAccount {
        address account = idToAccount[_accountId];

        require(
            accountToSigners[account].add(_signer) && signerToAccounts[_signer].add(account),
            "AccountAdmin: already added."
        );

        emit SignerAdded(_signer, account, _accountId);
    }

    /// @notice Called by an account (itself) when a signer is removed from it.
    function removeSignerToAccount(address _signer, bytes32 _accountId) external onlyAssociatedAccount {
        address account = _msgSender();

        require(
            accountToSigners[account].remove(_signer) && signerToAccounts[_signer].remove(account),
            "AccountAdmin: already removed."
        );

        emit SignerRemoved(_signer, account, _accountId);
    }

    /*///////////////////////////////////////////////////////////////
                            Read functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all accounts that a signer is a part of.
    function getAllAccountsOfSigner(address _signer) external view returns (address[] memory) {
        return signerToAccounts[_signer].values();
    }

    /// @notice Returns all signers that are part of an account.
    function getAllSignersOfAccount(address _account) external view returns (address[] memory) {
        return accountToSigners[_account].values();
    }

    /// @notice Returns the account associated with a particular accountId.
    function getAccount(bytes32 _accountId) external view returns (address) {
        return idToAccount[_accountId];
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Validates a signature.
    function _validateSignature(
        bytes32 _messageHash,
        bytes calldata _signature,
        address _intendedSigner
    ) internal view {
        bool validSignature = false;

        if (_intendedSigner.code.length > 0) {
            validSignature = MAGICVALUE == IERC1271(_intendedSigner).isValidSignature(_messageHash, _signature);
        } else {
            address recoveredSigner = _hashTypedDataV4(_messageHash).recover(_signature);
            validSignature = _intendedSigner == recoveredSigner;
        }

        require(validSignature, "AccountAdmin: invalid signer.");
    }
}
