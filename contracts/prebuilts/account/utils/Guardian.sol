//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IGuardian} from "../interface/IGuardian.sol";

contract Guardian is IGuardian {
    address[] private verifiedGuardians;
    address public owner;
   
    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }
    
    function addVerifiedGuardian() external {
        address guardian = msg.sender;
        require(guardian != address(0), "Cannot be a zero address");
        
        for(uint256 g = 0; g < verifiedGuardians.length; g++) {
            if(verifiedGuardians[g] == guardian) {
                revert GuardianAlreadyExists(guardian);
            }
        }
        emit GuardianAdded(guardian);
        verifiedGuardians.push(guardian);
    }

    function isVerifiedGuardian(address isVerified) public view returns(bool) {
        for(uint256 g = 0; g < verifiedGuardians.length; g++){
            if(verifiedGuardians[g] == isVerified) {
                return true;
            }
        }
        return false;
    }

    function removeVerifiedGuardian() external {
        address guardian = msg.sender;
        bool guardianFound = false;

        for(uint256 g = 0; g < verifiedGuardians.length; g++){
            if(verifiedGuardians[g] == guardian ) {
                // remove the guardian
                guardianFound = true;
                delete verifiedGuardians[g];
                emit GuardianRemoved(guardian);
            }
        }
        if(!guardianFound){
            revert NotAGuardian(guardian);
        }
    }

    ///////////////////////////////
    ///// Getter Functions ///////
    ///////////////////////////////

    function getVerifiedGuardians() external view onlyOwner returns(address[] memory) {
        return verifiedGuardians;
    }
}