// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountFactoryCore {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Account is created.
    event AccountCreated(address indexed account, address indexed accountAdmin);

    /// @notice Emitted when a new signer is added to an Account.
    event SignerAdded(address indexed account, address indexed signer);

    /// @notice Emitted when a new signer is added to an Account.
    event SignerRemoved(address indexed account, address indexed signer);

    /*///////////////////////////////////////////////////////////////
                        Extension Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new Account for admin.
    function createAccount(address admin, bytes calldata _data) external returns (address account);

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Account implementation.
    function accountImplementation() external view returns (address);

    /// @notice Returns all accounts created on the factory.
    function getAllAccounts() external view returns (address[] memory);

    /// @notice Returns the address of an Account that would be deployed with the given admin signer.
    function getAddress(address adminSigner, bytes calldata data) external view returns (address);

    /// @notice Returns all accounts on which a signer has (active or inactive) permissions.
    function getAccountsOfSigner(address signer) external view returns (address[] memory accounts);
}
