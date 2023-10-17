//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IGuardian} from "../interface/IGuardian.sol";

contract Guardian is IGuardian {
    address[] public verifiedGuardians;
    
    function addVerifiedGuardian(address guardian) external {
        require(guardian != address(0), "Cannot be a zero address");
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
}