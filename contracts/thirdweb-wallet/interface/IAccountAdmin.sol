// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IAccountAdmin {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Parameters to pass to create an account.
     *
     *  @param signer The address to set as the controlling signer of the account.
     *  @param credentials Unique credentials to associate with the account, required to be signed by `signer` every time transaction data is passed to the account.
     *  @param deploymentSalt The create2 salt for account deployment.
     *  @param initialAccountBalance The native token amount to send to the account on its creation.
     *  @param validityStartTimestamp The timestamp before which the account creation request is invalid.
     *  @param validityEndTimestamp The timestamp at and after which the account creation request is invalid.
     */
    struct CreateAccountParams {
        address signer;
        bytes32 credentials;
        bytes32 deploymentSalt;
        uint256 initialAccountBalance;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    /**
     *  @notice Parameters to pass to update the controlling signer of an account.
     *
     *  @param account The account whose signer is to be updated.
     *  @param newSigner The address to set as the new signer of the account.
     *  @param newCredentials The credentials to associate with the account, required to be signed by `signer` every time transaction data is passed to the account.
     *  @param validityStartTimestamp The timestamp before which the account creation request is invalid.
     *  @param validityEndTimestamp The timestamp at and after which the account creation request is invalid.
     */
    struct SignerUpdateParams {
        address account;
        address currentSigner;
        address newSigner;
        bytes32 newCredentials;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    /**
     *  @notice Parameters to pass to send transaction instructions to an account.
     *
     *  @param signer The signer of whose account will receive transaction instructions.
     *  @param credentials The credentials associated with the account that will receive transaction instructions.
     *  @param value Transaction option `value`: the native token amount to send with the transaction.
     *  @param gas Transaction option `gas`: The total amount of gas to pass in the call to the account.
     *  @param data The transaction data.
     *  @param validityStartTimestamp The timestamp before which the account creation request is invalid.
     *  @param validityEndTimestamp The timestamp at and after which the account creation request is invalid.
     */
    struct TransactionRequest {
        address signer;
        bytes32 credentials;
        uint256 value;
        uint256 gas;
        bytes data;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an account is created.
    event AccountCreated(address indexed account, address indexed signerOfAccount, address indexed creator);

    /// @notice Emitted when the signer for an account is updated.
    event SignerUpdated(address indexed account, address indexed newSigner);

    /// @notice Emitted on a call to an account.
    event CallResult(bool success, bytes result);

    /*///////////////////////////////////////////////////////////////
                                Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Creates an account.
     *
     *  @param params Parameters to pass to create an account.
     *  @param signature Signature from the intended signer of the account, signing account creation parameters.
     *  @return account The address of the account created.
     */
    function createAccount(CreateAccountParams calldata params, bytes calldata signature)
        external
        payable
        returns (address account);

    /**
     *  @notice Updates the signer of an account.
     *
     *  @param params Parameters to pass to update the signer of an account.
     *  @param signature Signature from the incumbent signer of the account, signing the parameters passed for udpating the signer of the account.
     */
    function changeSignerForAccount(SignerUpdateParams calldata params, bytes memory signature) external;

    /**
     *  @notice Calls an account to execute a transaction on the instructions of its controlling signer.
     *
     *  @param req Parameters to pass when sending transaction data to an account.
     *  @param signature Signature from the incumbent signer of the account, signing the parameters passed for sending transaction data to the account.
     *
     *  @return success Returns whether the call to the account was successful.
     *  @return result Returns the call result of the call to the account.
     */
    function execute(TransactionRequest calldata req, bytes memory signature)
        external
        payable
        returns (bool success, bytes memory result);
}
