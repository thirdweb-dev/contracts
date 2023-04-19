// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ITWAccountFactory {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /// @notice Smart account details: address and ID (used as salt).
    struct AccountInfo {
        string id;
        address account;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Account is created.
    event AccountCreated(address indexed account, address indexed accountAdmin, string indexed accountId);

    /*///////////////////////////////////////////////////////////////
                        Extension Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new Account with the given admin and accountId used as salt.
    function createAccount(address admin, string memory accountId) external returns (address account);

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Account implementation.
    function accountImplementation() external view returns (address);

    /// @notice Returns the address of an Account that would be deployed with the given accountId as salt.
    function getAddress(string memory accountId) external view returns (address);

    /// @notice Returns the list of accounts created by a signer.
    function getAccountsOfSigner(address _signer) external view returns (AccountInfo[] memory);

    /// @notice Returns the list of all accounts.
    function getAllAccounts() external view returns (AccountInfo[] memory);
}
