// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IAccountGuardian} from "../interface/IAccountGuardian.sol";
import {Guardian} from "./Guardian.sol";

abstract contract AccountGuardian is IAccountGuardian {
    Guardian guardianContract = new Guardian();
    address[] accountGuardians; 

    function addGuardian(address guardian) external returns(bool) {
        if(guardianContract.isVerifiedGuardian(guardian)) {
            accountGuardians.push(guardian);
            return true;
        } else {
            return false;
        }
    }   
}