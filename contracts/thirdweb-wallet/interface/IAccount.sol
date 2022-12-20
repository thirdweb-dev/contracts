// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _hash
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);
}

interface IAccount is IERC1271 {
    ////////// Execute a transaction. Send native tokens or call a smart contract. //////////

    /// @notice Emitted when a wallet performs a call.
    event TransactionExecuted(
        address indexed signer,
        address indexed target,
        bytes data,
        uint256 indexed nonce,
        uint256 value,
        uint256 gas
    );

    /**
     *  @notice Parameters to pass to make the wallet perform a call.
     *
     *  @param target The call's target address.
     *  @param data The call data.
     *  @param nonce The nonce of the smart contract wallet at the time of making the call.
     *  @param value The value to send in the call.
     *  @param gas The gas to send in the call.
     *  @param validityStartTimestamp The timestamp before which the account creation request is invalid.
     *  @param validityEndTimestamp The timestamp at and after which the account creation request is invalid.
     */
    struct TransactionParams {
        address signer;
        address target;
        bytes data;
        uint256 nonce;
        uint256 value;
        uint256 gas;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    /**
     *  @notice Executes a transaction. Sends native tokens or calls a smart contract.
     *
     *  @param params Parameters to pass to make the wallet execute a transaction.
     *  @param signature A signature of intent from the wallet's signer, produced on signing the function parameters.
     */
    function execute(TransactionParams calldata params, bytes memory signature) external payable returns (bool success);

    ////////// Deploy a smart contract //////////

    /// @notice Emitted when the wallet deploys a smart contract.
    event ContractDeployed(address indexed deployment);

    /// @notice Deploys a smart contract.
    function deploy(
        bytes calldata bytecode,
        bytes32 salt,
        uint256 value
    ) external payable returns (address deployment);

    ////////// Changing signer composition of the account //////////

    /// @notice Emitted when a signer is added to the account.
    event SignerAdded(address signer);

    /// @notice Emitted when a signer is removed from the account.
    event SignerRemoved(address signer);

    /// @notice Emitted when an admin is added to the account.
    event AdminAdded(address signer);

    /// @notice Emitted when an admin is removed from the account.
    event AdminRemoved(address signer);

    /// @notice Adds an admin to the account.
    function addAdmin(address signer, bytes32 credentials) external;

    /// @notice Removes an admin from the account.
    function removeAdmin(address signer, bytes32 credentials) external;

    /// @notice Adds a signer to the account.
    function addSigner(address signer, bytes32 credentials) external;

    /// @notice Removes a signer from the account.
    function removeSigner(address signer, bytes32 credentials) external;

    ////////// Approve non-admin signers for function calls //////////

    /// @notice Emitted when a signer is approved to call `_selector` function on `_target` smart contract.
    event ApprovalForSigner(address indexed signer, bytes4 indexed selector, address indexed target, bool isApproved);

    /// @notice A struct representing a call target (fn selector + smart contract).
    struct CallTarget {
        bytes4 selector;
        address targetContract;
    }

    /// @notice Approves a signer to be able to call `_selector` function on `_target` smart contract.
    function approveSignerFor(
        address signer,
        bytes4 selector,
        address target
    ) external;

    /// @notice Disapproves a signer from being able to call `_selector` function on `_target` smart contract.
    function disapproveSignerFor(
        address signer,
        bytes4 selector,
        address target
    ) external;

    /// @notice Returns all call targets approved for a given signer.
    function getAllApprovedForSigner(address signer) external view returns (CallTarget[] memory approvedTargets);
}
