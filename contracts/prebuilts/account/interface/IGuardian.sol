// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IGuardian {

    /**
     * @param guardian wallet address of the guardian being added.
     */
    event GuardianAdded(address indexed guardian);


    /**
     * @notice This function will add a verified
     * guardian's address to the verified guardian list.
     * @param guardian verified wallet address.
     */
    function addVerifiedGuardian(address guardian) external;

    /**
     * @notice will check if an address is a verified guardian
     * @param isVerified address to be checked if verified
     * @return bool Boolean value indicating if a address is a verified
     * guardian or not.
     */
    function isVerifiedGuardian(address isVerified) external returns(bool);

}