// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./Account.sol";
import "./interface/IAccountAdmin.sol";

import "../extension/Multicall.sol";

import "../openzeppelin-presets/metatx/ERC2771Context.sol";

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/**
 *  Basic actions:
 *      - Create accounts.
 *      - Change signer of account.
 *      - Relay transaction to contract wallet.
 */

contract AccountAdmin is IAccountAdmin, EIP712, Multicall, ERC2771Context {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    bytes32 private constant CREATE_TYPEHASH =
        keccak256(
            "CreateAccountParams(address signer,bytes32 credentials,bytes32 deploymentSalt,uint256 initialAccountBalance,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant SIGNER_UPDATE_TYPEHASH =
        keccak256(
            "SignerUpdateParams(address account,address newSigner,address currentSigner,bytes32 newCredentials,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant TRANSACTION_TYPEHASH =
        keccak256(
            "TransactionRequest(address signer,bytes32 credentials,uint256 value,uint256 gas,bytes data,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from credentials => signer.
    mapping(bytes32 => address) public signerOf;

    /// @dev Mapping from signer => credentials.
    mapping(address => bytes32) public credentialsOf;

    /// @dev Mapping from hash(signer, credentials) => account.
    mapping(bytes32 => address) public accountOf;

    /*///////////////////////////////////////////////////////////////
                        Constructor & Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory _trustedForwarder)
        EIP712("thirdwebWallet_Admin", "1")
        ERC2771Context(_trustedForwarder)
    {}

    /// @dev Checks whether a request is processed within its respective valid time window.
    modifier onlyValidTimeWindow(uint128 validityStartTimestamp, uint128 validityEndTimestamp) {
        /// @validate: request to create account not pre-mature or expired.
        require(
            validityStartTimestamp <= block.timestamp && block.timestamp < validityEndTimestamp,
            "AccountAdmin: request premature or expired."
        );

        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
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
        require(signerOf[_params.credentials] == address(0), "AccountAdmin: credentials already used.");
        require(credentialsOf[_params.signer] == bytes32(0), "AccountAdmin: signer already has account.");

        /// @validate: (By Create2) No repeat deployment salt.
        account = Create2.deploy(
            _params.initialAccountBalance,
            _params.deploymentSalt,
            abi.encodePacked(type(Account).creationCode, abi.encode(address(this), _params.signer))
        );

        _setSignerForAccount(account, _params.signer, _params.credentials);

        emit AccountCreated(account, _params.signer, _msgSender());
    }

    /// @notice Updates the (signer, credential) pair for an account.
    function changeSignerForAccount(SignerUpdateParams calldata _params, bytes calldata _signature)
        external
        onlyValidTimeWindow(_params.validityStartTimestamp, _params.validityEndTimestamp)
    {
        /// @validate: no empty new credentials.
        require(_params.newCredentials != bytes32(0), "AccountAdmin: invalid credentials.");
        /// @validate: no credentials re-use.
        require(signerOf[_params.newCredentials] == address(0), "AccountAdmin: credentials already used.");
        /// @validate: new signer to set does not already have an account.
        require(credentialsOf[_params.newSigner] == bytes32(0), "AccountAdmin: signer already has account.");

        /// @validate: is valid EIP 1271 signature.
        bytes32 messageHash = keccak256(
            abi.encode(
                SIGNER_UPDATE_TYPEHASH,
                _params.account,
                _params.newSigner,
                _params.currentSigner,
                _params.newCredentials,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        /// @validate: signature-of-intent from target signer.
        _validateSignature(messageHash, _signature, _params.currentSigner);

        bytes32 currentCredentials = credentialsOf[_params.currentSigner];
        bytes32 currentPair = keccak256(abi.encode(_params.currentSigner, currentCredentials));

        /// @validate: Caller is account for (signer, credentials) pair.
        require(accountOf[currentPair] == _params.account, "AccountAdmin: incorrect account provided.");

        delete signerOf[currentCredentials];
        delete credentialsOf[_params.currentSigner];
        delete accountOf[currentPair];

        _setSignerForAccount(_params.account, _params.newSigner, _params.newCredentials);

        require(
            Account(payable(_params.account)).updateSigner(_params.newSigner),
            "AccountAdmin: failed to update signer."
        );
    }

    /// @notice Calls an account with transaction data.
    function execute(TransactionRequest calldata req, bytes calldata signature)
        external
        payable
        onlyValidTimeWindow(req.validityStartTimestamp, req.validityEndTimestamp)
        returns (bool, bytes memory)
    {
        require(req.value == msg.value, "AccountAdmin: incorrect value sent.");

        bytes32 messageHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                req.signer,
                req.credentials,
                req.value,
                req.gas,
                keccak256(req.data),
                req.validityStartTimestamp,
                req.validityEndTimestamp
            )
        );
        /// @validate: signature-of-intent from target signer.
        _validateSignature(messageHash, signature, req.signer);

        address target = accountOf[keccak256(abi.encode(req.signer, req.credentials))];

        bool success;
        bytes memory result;
        if (req.gas > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = target.call{ gas: req.gas, value: req.value }(req.data);
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = target.call{ value: req.value }(req.data);
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
        assert(gasleft() > req.gas / 63);

        emit CallResult(success, result);

        return (success, result);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Associates a (signer, credential) pair with an account.
    function _setSignerForAccount(
        address _account,
        address _signer,
        bytes32 _credentials
    ) internal {
        signerOf[_credentials] = _signer;
        credentialsOf[_signer] = _credentials;
        accountOf[keccak256(abi.encode(_signer, _credentials))] = _account;

        emit SignerUpdated(_account, _signer);
    }

    /// @dev Validates a signature.
    function _validateSignature(
        bytes32 _messageHash,
        bytes calldata _signature,
        address _intendedSigner
    ) internal view {
        bool validSignature = false;

        if (_intendedSigner.code.length > 0) {
            validSignature = MAGICVALUE == Account(payable(_intendedSigner)).isValidSignature(_messageHash, _signature);
        } else {
            address recoveredSigner = _hashTypedDataV4(_messageHash).recover(_signature);
            validSignature = _intendedSigner == recoveredSigner;
        }

        require(validSignature, "AccountAdmin: invalid signer.");
    }
}
