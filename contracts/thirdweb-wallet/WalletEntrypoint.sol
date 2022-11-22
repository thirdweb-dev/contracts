// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./Wallet.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 *  Basic actions:
 *      - Create accounts. ✅
 *      - Change signer of account. ✅
 *      - Relay transaction to contract wallet. ✅
 */

interface IWalletEntrypoint {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    struct TransactionRequest {
        address signer;
        bytes32 credentials;
        uint256 value;
        uint256 gas;
        bytes data;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event AccountCreated(address indexed signer);
    event CallResult(bool success, bytes result);

    /*///////////////////////////////////////////////////////////////
                                Functions
    //////////////////////////////////////////////////////////////*/

    function createAccount(
        bytes32 credentials,
        address signer,
        bytes calldata signature
    ) external returns (address account);

    function changeSignerForAccount(
        address newSigner,
        bytes32 messageHash,
        bytes memory signature
    ) external;

    function execute(TransactionRequest calldata req, bytes memory signature)
        external
        payable
        returns (bool, bytes memory);
}

contract WalletEntrypoint is IWalletEntrypoint, EIP712 {
    using ECDSA for bytes32;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    bytes32 private constant CREDENTIALS_TYPEHASH = keccak256("Create(bytes32 credentials)");
    bytes32 private constant TRANSACTION_TYPEHASH =
        keccak256("TransactionRequest(address signer,bytes32 credentials,uint256 value,uint256 gas,bytes data)");

    /// @dev Mapping from credentials => signer.
    mapping(bytes32 => address) private signerOf;

    /// @dev Mapping from signer => credentials.
    mapping(address => bytes32) private credentialsOf;

    /// @dev Mapping from hash(signer, credentials) => account.
    mapping(bytes32 => address) private accountOf;

    constructor() EIP712("thirdwebWallet_Admin", "1") {}

    function createAccount(
        bytes32 credentials,
        address signer,
        bytes calldata signature
    ) external returns (address account) {
        require(credentials != bytes32(0), "WalletEntrypoint: invalid credentials.");
        require(signerOf[credentials] == address(0), "WalletEntrypoint: credentials already in use.");

        address recoveredSigner = _hashTypedDataV4(keccak256(abi.encode(CREDENTIALS_TYPEHASH, credentials))).recover(
            signature
        );
        require(signer == recoveredSigner, "WalletEntrypoint: invalid signer.");

        account = address(new Wallet(address(this), signer));

        signerOf[credentials] = signer;
        credentialsOf[signer] = credentials;
        accountOf[keccak256(abi.encode(signer, credentials))] = account;
    }

    function changeSignerForAccount(
        address newSigner,
        bytes32 messageHash,
        bytes memory signature
    ) external {
        address account = msg.sender;

        require(
            MAGICVALUE == Wallet(account).isValidSignature(messageHash, signature),
            "WalletEntrypoint: invalid signer."
        );

        address signer = _hashTypedDataV4(messageHash).recover(signature);
        bytes32 credentials = credentialsOf[signer];
        require(credentials != bytes32(0), "WalletEntrypoint: invalid credentials.");

        signerOf[credentials] = newSigner;
        credentialsOf[newSigner] = credentials;

        delete credentialsOf[signer];
    }

    function execute(TransactionRequest calldata req, bytes memory signature)
        public
        payable
        returns (bool, bytes memory)
    {
        address recoveredSigner = _hashTypedDataV4(
            keccak256(abi.encode(TRANSACTION_TYPEHASH, req.signer, req.credentials, req.value, req.gas, req.data))
        ).recover(signature);
        require(req.signer == recoveredSigner, "WalletEntrypoint: signer mismatch.");
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
}
