// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

////////// Interfaces //////////
import "./interface/IAccountAdmin.sol";
import "./interface/IAccount.sol";

////////// Helpers //////////
import "./Account.sol";

////////// Utils //////////
import "../openzeppelin-presets/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

////////// NOTE(S) //////////
/**
 *  - One Signer can be a part of many Accounts.
 *  - One Account can have many Signers.
 *  - A Signer-Credential pair hash can only be used/associated with one unique account.
 *    i.e. a Signer must use unique credentials for each Account it wants to be a part of.
 *
 *  - How does data fetching work?
 *      - Fetch all accounts for a single signer.
 *      - Fetch all signers for a single account.
 *      - Fetch the unique account for a signer-credential pair.
 */

contract AccountAdmin is IAccountAdmin, EIP712, ERC2771Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    bytes32 private constant CREATE_TYPEHASH =
        keccak256(
            "CreateAccountParams(address signer,bytes32 credentials,bytes32 deploymentSalt,uint256 initialAccountBalance,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant RELAY_TYPEHASH =
        keccak256(
            "RelayRequestParam(address signer,bytes32 credentials,uint256 value,uint256 gas,bytes data,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    address[] private trustedForwarders;

    /// @dev Signer => Accounts where signer is an actor.
    mapping(address => EnumerableSet.AddressSet) private signerToAccounts;

    /// @dev Account => Signers that are actors in account.
    mapping(address => EnumerableSet.AddressSet) private accountToSigners;

    /// @dev Signer-Credential pair => Account.
    mapping(bytes32 => address) private pairHashToAccount;

    /// @dev Address => whether the address is of an account created via this admin contract.
    mapping(address => bool) public isAssociatedAccount;

    constructor(address[] memory _trustedForwarders)
        EIP712("thirdweb_wallet_admin", "1")
        ERC2771Context(_trustedForwarders)
    {
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

    /// @notice Creates an account for a (signer, credential) pair.
    function createAccount(CreateAccountParams calldata _params, bytes calldata _signature)
        external
        payable
        onlyValidTimeWindow(_params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (address account)
    {
        /// @validate: credentials not empty.
        require(_params.credentials != bytes32(0), "AccountAdmin: invalid credentials.");
        /// @validate: sent initial account balance.
        require(_params.initialAccountBalance == msg.value, "AccountAdmin: incorrect value sent.");

        bytes32 messageHash = keccak256(
            abi.encode(
                CREATE_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.deploymentSalt,
                _params.initialAccountBalance,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        /// @validate: signature-of-intent from target signer.
        _validateSignature(messageHash, _signature, _params.signer);

        /// @validate: new signer to set does not already have an account.
        bytes32 pairHash = keccak256(abi.encode(_params.signer, _params.credentials));
        require(pairHashToAccount[pairHash] == address(0), "AccountAdmin: credentials already used.");

        /// @validate: (By Create2) No repeat deployment salt.
        address[] memory forwarders = trustedForwarders;
        account = Create2.deploy(
            _params.initialAccountBalance,
            _params.deploymentSalt,
            abi.encodePacked(type(Account).creationCode, abi.encode(forwarders, address(this), _params.signer))
        );

        isAssociatedAccount[account] = true;
        accountToSigners[account].add(_params.signer);
        signerToAccounts[_params.signer].add(account);
        pairHashToAccount[pairHash] = account;

        emit AccountCreated(account, _params.signer, _msgSender(), _params.credentials);
        emit SignerAdded(_params.signer, account, pairHash);
    }

    /*///////////////////////////////////////////////////////////////
                Relaying transaction data to an account.
    //////////////////////////////////////////////////////////////*/

    /// @notice Calls an account with transaction data.
    function relay(RelayRequestParams calldata _params) external payable returns (bool, bytes memory) {
        require(_params.value == msg.value, "AccountAdmin: incorrect value sent.");

        bytes32 pairHash = keccak256(abi.encode(_params.signer, _params.credentials));
        address account = pairHashToAccount[pairHash];

        /// @validate: account exists for signer-credential pair.
        require(account != address(0), "AccountAdmin: no account with given credentials.");

        bool success;
        bytes memory result;
        if (_params.gas > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = account.call{ gas: _params.gas, value: _params.value }(_params.data);
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = account.call{ value: _params.value }(_params.data);
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
        assert(gasleft() > _params.gas / 63);

        emit CallResult(success, result);

        return (success, result);
    }

    /*///////////////////////////////////////////////////////////////
                Changing signer composition of accounts
    //////////////////////////////////////////////////////////////*/

    /// @notice Called by an account (itself) when a signer is added to it.
    function addSignerToAccount(address _signer, bytes32 _credentials) external onlyAssociatedAccount {
        address account = _msgSender();
        bytes32 pairHash = keccak256(abi.encode(_signer, _credentials));

        require(
            accountToSigners[account].add(_signer) &&
                signerToAccounts[_signer].add(account) &&
                pairHashToAccount[pairHash] == address(0),
            "AccountAdmin: already added."
        );

        pairHashToAccount[pairHash] = account;

        emit SignerAdded(_signer, account, pairHash);
    }

    /// @notice Called by an account (itself) when a signer is removed from it.
    function removeSignerToAccount(address _signer, bytes32 _credentials) external onlyAssociatedAccount {
        address account = _msgSender();
        bytes32 pairHash = keccak256(abi.encode(_signer, _credentials));

        require(
            accountToSigners[account].remove(_signer) && signerToAccounts[_signer].remove(account),
            "AccountAdmin: already removed."
        );

        delete pairHashToAccount[pairHash];

        emit SignerRemoved(_signer, account, pairHash);
    }

    /*///////////////////////////////////////////////////////////////
                            Read functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all accounts that a signer is a part of.
    function getAllAccountsOfSigner(address _signer) external view returns (address[] memory accounts) {
        uint256 len = signerToAccounts[_signer].length();
        accounts = new address[](len);

        for (uint256 i = 0; i < len; i += 1) {
            accounts[i] = signerToAccounts[_signer].at(i);
        }
    }

    /// @notice Returns all signers that are part of an account.
    function getAllSignersOfAccount(address _account) external view returns (address[] memory signers) {
        uint256 len = accountToSigners[_account].length();
        signers = new address[](len);

        for (uint256 i = 0; i < len; i += 1) {
            signers[i] = accountToSigners[_account].at(i);
        }
    }

    /// @notice Returns the account associated with a particular signer-credential pair.
    function getAccountForCredential(address _signer, bytes32 _credentials) external view returns (address) {
        bytes32 pair = keccak256(abi.encode(_signer, _credentials));
        return pairHashToAccount[pair];
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
