// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param _hash      Hash of the data to be signed
     * @param _signature Signature byte array associated with _hash
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
}

interface IAccount is IERC1271 {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Parameters to pass to make the wallet deploy a smart contract.
     *
     *  @param bytecode The smart contract bytcode to deploy.
     *  @param salt The create2 salt for smart contract deployment.
     *  @param value The amount of native tokens to pass to the contract on creation.
     *  @param nonce The nonce of the smart contract wallet at the time of deploying the contract.
     *  @param validityStartTimestamp The timestamp before which the account creation request is invalid.
     *  @param validityEndTimestamp The timestamp at and after which the account creation request is invalid.
     */
    struct DeployParams {
        address signer;
        bytes bytecode;
        bytes32 salt;
        uint256 value;
        uint256 nonce;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

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

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the signer is added to the account.
    event SignerAdded(address signer);

    /// @notice Emitted when the signer is removed from the account.
    event SignerRemoved(address signer);

    /// @notice Emitted when the wallet deploys a smart contract.
    event ContractDeployed(address indexed deployment);

    /// @notice Emitted when a wallet performs a call.
    event TransactionExecuted(
        address indexed signer,
        address indexed target,
        bytes data,
        uint256 indexed nonce,
        uint256 value,
        uint256 txGas
    );

    /*///////////////////////////////////////////////////////////////
                                Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Performs a call; sends native tokens or calls a smart contract.
     *
     *  @param params Parameters to pass to make the wallet perform a call.
     *  @param signature A signature of intent from the wallet's signer, produced on signing the function parameters.
     */
    function execute(TransactionParams calldata params, bytes memory signature) external payable returns (bool success);

    /**
     *  @notice Deploys a smart contract.
     *
     *  @param params Parameters to pass to make the wallet deploy a smart contract.
     *  @param signature A signature of intent from the wallet's signer, produced on signing the function parameters.
     */
    function deploy(DeployParams calldata params, bytes memory signature) external payable returns (address deployment);

    /**
     *  @notice Adds a signer to the smart contract.
     *
     *  @param signer The address to add as a signer to the smart contract.
     */
    function addSigner(address signer) external returns (bool success);

    /**
     *  @notice Removes a signer to the smart contract.
     *
     *  @param signer The address to remove as a signer of the smart contract.
     */
    function removeSigner(address signer) external returns (bool success);
}
