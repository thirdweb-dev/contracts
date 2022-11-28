// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./Wallet.sol";
import "./interface/IWalletEntrypoint.sol";

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/**
 *  Basic actions:
 *      - Create accounts. ✅
 *      - Change signer of account. ✅
 *      - Relay transaction to contract wallet. ✅
 */

contract WalletEntrypoint is IWalletEntrypoint, EIP712 {
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
        keccak256("TransactionRequest(address signer,bytes32 credentials,uint256 value,uint256 gas,bytes data)");

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from credentials => signer.
    mapping(bytes32 => address) private signerOf;

    /// @dev Mapping from signer => credentials.
    mapping(address => bytes32) private credentialsOf;

    /// @dev Mapping from hash(signer, credentials) => account.
    mapping(bytes32 => address) private accountOf;

    /*///////////////////////////////////////////////////////////////
                        Constructor & Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor() EIP712("thirdwebWallet_Admin", "1") {}

    /// @dev Checks whether a request is processed within its respective valid time window.
    modifier onlyValidTimeWindow(uint128 validityStartTimestamp, uint128 validityEndTimestamp) {
        /// @validate: request to create account not pre-mature or expired.
        require(
            validityStartTimestamp <= block.timestamp && block.timestamp < validityEndTimestamp,
            "WalletEntrypoint: request premature or expired."
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
        require(_params.credentials != bytes32(0), "WalletEntrypoint: invalid credentials.");
        /// @validate: sent initial account balance.
        require(_params.initialAccountBalance == msg.value, "WalletEntrypoint: incorrect value sent.");

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

        bytes32 signerCredentialPair = keccak256(abi.encode(_params.signer, _params.credentials));
        /// @validate: No account already associated with (signer, credentials) pair.
        require(accountOf[signerCredentialPair] == address(0), "WalletEntrypoint: credentials already in use.");

        /// @validate: (By Create2) No repeat deployment salt.
        account = Create2.deploy(
            _params.initialAccountBalance,
            _params.deploymentSalt,
            abi.encodePacked(type(Wallet).creationCode, abi.encode(address(this), _params.signer))
        );

        _setSignerForAccount(account, _params.signer, _params.credentials);

        emit AccountCreated(account, _params.signer, msg.sender);
    }

    /// @notice Updates the (signer, credential) pair for an account.
    function changeSignerForAccount(SignerUpdateParams calldata _params, bytes memory _signature)
        external
        onlyValidTimeWindow(_params.validityStartTimestamp, _params.validityEndTimestamp)
    {
        /// @validate: no empty new credentials.
        require(_params.newCredentials != bytes32(0), "WalletEntrypoint: invalid credentials.");
        /// @validate: new signer to set does not already have an account.
        require(credentialsOf[_params.newSigner] == bytes32(0), "WalletEntrypoint: signer already has account.");

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
        require(accountOf[currentPair] == _params.account, "WalletEntrypoint: incorrect account provided.");

        delete signerOf[currentCredentials];
        delete credentialsOf[_params.currentSigner];
        delete accountOf[currentPair];

        _setSignerForAccount(_params.account, _params.newSigner, _params.newCredentials);

        require(
            Wallet(payable(_params.account)).updateSigner(_params.newSigner),
            "WalletEntrypoint: failed to update signer."
        );
    }

    /// @notice Calls an account with transaction data.
    function execute(TransactionRequest calldata req, bytes memory signature)
        public
        payable
        onlyValidTimeWindow(req.validityStartTimestamp, req.validityEndTimestamp)
        returns (bool, bytes memory)
    {
        bytes32 messageHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                req.signer,
                req.credentials,
                req.value,
                req.gas,
                req.data,
                req.validityStartTimestamp,
                req.validityEndTimestamp
            )
        );
        /// @validate: signature-of-intent from target signer.
        _validateSignature(messageHash, signature, req.signer);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = accountOf[keccak256(abi.encode(req.signer, req.credentials))].call{
            gas: req.gas,
            value: req.value
        }(req.data);

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
        bytes memory _signature,
        address _intendedSigner
    ) internal view {
        bool validSignature = false;

        if (_intendedSigner.code.length > 0) {
            validSignature = MAGICVALUE == Wallet(payable(_intendedSigner)).isValidSignature(_messageHash, _signature);
        } else {
            address recoveredSigner = _hashTypedDataV4(_messageHash).recover(_signature);
            validSignature = _intendedSigner == recoveredSigner;
        }

        require(validSignature, "WalletEntrypoint: invalid signer.");
    }
}
