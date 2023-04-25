// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountFactory {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Account is created.
    event AccountCreated(address indexed account, address indexed accountAdmin, string accountId);

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
}
