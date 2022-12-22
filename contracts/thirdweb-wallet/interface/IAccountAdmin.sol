// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IAccountAdmin {
    ////////// Creating accounts //////////

    /// @notice Emitted when an account is created.
    event AccountCreated(
        address indexed account,
        address indexed signerOfAccount,
        address indexed creator,
        bytes32 accountId
    );

    /**
     *  @notice Parameters to pass to create an account.
     *
     *  @param signer The address to set as the controlling signer of the account.
     *  @param accountId Unique accountId to associate with the account, required to be signed by `signer` every time transaction data is passed to the account.
     *  @param deploymentSalt The create2 salt for account deployment.
     *  @param initialAccountBalance The native token amount to send to the account on its creation.
     *  @param validityStartTimestamp The timestamp before which the account creation request is invalid.
     *  @param validityEndTimestamp The timestamp at and after which the account creation request is invalid.
     */
    struct CreateAccountParams {
        address signer;
        bytes32 accountId;
        bytes32 deploymentSalt;
        uint256 initialAccountBalance;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

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

    ////////// Relaying transaction to account //////////

    /// @notice Emitted on a call to an account.
    event CallResult(address indexed signer, address indexed account, bool success);

    /**
     *  @notice Parameters to pass to send transaction instructions to an account.
     *
     *  @param signer The signer of whose account will receive transaction instructions.
     *  @param accountId The accountId associated with the account that will receive transaction instructions.
     *  @param value Transaction option `value`: the native token amount to send with the transaction.
     *  @param gas Transaction option `gas`: The total amount of gas to pass in the call to the account. (Optional: if 0 then no particular gas is specified in the call.)
     *  @param data The transaction data.
     */
    struct RelayRequestParams {
        address signer;
        bytes32 accountId;
        uint256 value;
        uint256 gas;
        bytes data;
    }

    /**
     *  @notice Calls an Account to execute a transaction.
     *
     *  @param params Parameters to pass when sending transaction data to an account.
     *
     *  @return success Returns whether the call to the account was successful.
     *  @return result Returns the call result of the call to the account.
     */
    function relay(RelayRequestParams calldata params) external payable returns (bool success, bytes memory result);

    ////////// Changes to signer composition of accounts //////////

    /// @notice Emitted when a signer is added to an account.
    event SignerAdded(address signer, address account, bytes32 pairHash);

    /// @notice Emitted when a signer is removed from an account.
    event SignerRemoved(address signer, address account, bytes32 pairHash);

    /**
     *  @notice Called by an account (itself) when a signer is added to it.
     *
     *  @param signer The signer added to the account.
     *  @param accountId The accountId of the signer used with the relevant account.
     */
    function addSignerToAccount(address signer, bytes32 accountId) external;

    /**
     *  @notice Called by an account (itself) when a signer is removed from it.
     *
     *  @param signer The signer removed from the account.
     *  @param accountId The accountId of the signer used with the relevant account.
     */
    function removeSignerToAccount(address signer, bytes32 accountId) external;

    ////////// Data fetching //////////

    /// @notice Returns all accounts that a signer is a part of.
    function getAllAccountsOfSigner(address signer) external view returns (address[] memory accounts);

    /// @notice Returns all signers that are part of an account.
    function getAllSignersOfAccount(address account) external view returns (address[] memory signers);

    /// @notice Returns the account associated with a particular signer-accountId pair.
    function getAccount(address signer, bytes32 accountId) external view returns (address);
}
