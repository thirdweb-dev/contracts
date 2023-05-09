// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountFactory {
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

    /// @notice Callback function for an Account to register its signers.
    function addSigner(address signer) external;

    /// @notice Callback function for an Account to un-register its signers.
    function removeSigner(address signer) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Account implementation.
    function accountImplementation() external view returns (address);

    /// @notice Returns the address of an Account that would be deployed with the given admin signer.
    function getAddress(address adminSigner) external view returns (address);

    /// @notice Returns all signers of an account.
    function getSignersOfAccount(address account) external view returns (address[] memory signers);

    /// @notice Returns all accounts that the given address is a signer of.
    function getAccountsOfSigner(address signer) external view returns (address[] memory accounts);
}
