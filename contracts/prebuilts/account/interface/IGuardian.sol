// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IGuardian {

     //////////////////////////////////////
    /////////// Errors ////////////////
    //////////////////////////////////////

 /**
     * Emits error if the guardian already exists
     * @param guardian wallet address of the guardian being added.
     */
    error GuardianAlreadyExists(address guardian);

    /**
     * Throws this error when a non-verified guardian calls the removeGuardian() function
     * @param guardian guardian address to be removed
     */
    error NotAGuardian(address guardian);

     //////////////////////////////////////
    /////////// Events ////////////////
    //////////////////////////////////////

    /**
     * @param guardian address of the guardian being added.
     */
    event GuardianAdded(address indexed guardian);

    /**
     * @param guardian address of the guardian being removed.
     */
    event GuardianRemoved(address indexed guardian);
   
    /////////////////////////////////////
    /////////// External Functions //////
    //////////////////////////////////////

    /**
     * @notice This function will add the sender as a verified
     * guardian to thirdweb's guardian list.
     */
    function addVerifiedGuardian() external;

    /**
     * @notice will check if an address is a verified guardian
     * @param isVerified address to be checked if verified
     * @return bool Boolean value indicating if a address is a verified
     * guardian or not.
     */
    function isVerifiedGuardian(address isVerified) external returns(bool);

    /**
     * @notice Remove the sender as a verified thirdweb guardian.
     */
    function removeVerifiedGuardian() external;


    /**
     * @notice Used to maintain a record of each account and it's guardian (accountGuardian) contract instance
     * @param account Address of the account that got initialised
     * @param accountGuardian Address of the guardian contract of the
     * account
     */
    function linkAccountToAccountGuardian(address account, address accountGuardian) external;

    //////////////////////////////////////
    /////////// Getter Function //////////
    //////////////////////////////////////

    /**
     * Returns the list of verified guardians.
     * Can only be called by the owner.
     */
    function getVerifiedGuardians() external view returns(address[] memory);

    /**
     * @notice Returns the accountGuardian address of an account
     * @param account account
     * @return address accountGuardian
     */
    function getAccountGuardian(address account) external view returns(address);
}