// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountGuardian {
    
     /*///////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/

    /**
     * An event emitted when guardian is added by a smart wallet user.
     * @param guardian - the verified address of a wallet to be
     * added as a guardian.
     */
    event GuardianAdded(address indexed guardian);

    /**
     * An event emitted when guardian is removed by a smart wallet user.
     * @param guardian the address of guardian removed
     */
    event GuardianRemoved(address indexed guardian);


    /*///////////////////////////////////////////////////////////////
                        Errors
    //////////////////////////////////////////////////////////////*/

    /**
     * An error thrown when guardian being added is not verified by the Thirdweb's
     * guardian signup dapp.
     * @param guardian address that was not added as a guardian
     */
    error GuardianNotVerified(address guardian);

    /**
     * An error thrown if the guardian the user is trying to remove is not a part of 
     * the user's guardian list.
     * @param guardian address which the user was trying to remove from their 
     * guardian list but was not the guardian
     */
    error NotAGuardian(address guardian);

    /**
     * An error thrown when the user tries to remove a guardian from the list during
     * an active account recovery request
     * @param guardian address of guardian user is trying to remove
     * @param recoveryHash active recovery request hash
     */
    error GuardianNotRemovedDueToActiveRecoveryRequest(
        address guardian,
        bytes32 recoveryHash
        );


     /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/


    /**
     * @notice Add guardians for your smart-wallet.
     * @dev The guardian address needs to connect to the thirdweb’s 
     * guardian signup dapp by accepting the signin request.
     * @param guardian the verified address of a wallet to be
     * added as a guardian.
     */
    function addGuardian(address guardian) external;


    /**
     * @notice A user will be able to remove allotted guardian(s) from
     * their smart-wallet guardian list.
     * @dev The address should be a registered guardian of the account.
     * @param guardian address of the guardian the user wishes to remove.
     */
    function removeGuardian(address guardian) external;

    /**
     * @notice Returns a list of all added guardians of the sender.
     * @return List of guardians of the sender smart-wallet.
     */
    function getAllGuardians() external returns(address[] memory);

    /**
     * @notice Returns a bool value indicating if the guardian is that
     * account's guardian or not.
     * @param guardian guardian to be checked for
     * @return bool
     */
    function isAccountGuardian(address guardian) external view returns (bool); 
    
    /**
     * @notice Sign the lock request
     */
}