// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IAccountGuardian} from "../interface/IAccountGuardian.sol";
import {Guardian} from "./Guardian.sol";

contract AccountGuardian is IAccountGuardian {
    Guardian public guardianContract;
    address[] private accountGuardians;
    address public owner;

    error NotAccountOwner();

    modifier onlyOwner() {
        if(owner != msg.sender) {
            revert NotAccountOwner();
        }
        _;
    }

    constructor() {
        guardianContract = new Guardian();
        owner = msg.sender;
    }

    ////////////////////////////
    ///// External Functions////
    ////////////////////////////

    function addGuardian(address guardian) external onlyOwner {
        if(guardianContract.isVerifiedGuardian(guardian)) {
            accountGuardians.push(guardian);
            emit GuardianAdded(guardian);
        } else {
            revert GuardianNotVerified(guardian);
        }
    }

    function removeGuardian(address guardian) external onlyOwner {
        bool guardianFound = false;
        for(uint256 g = 0; g < accountGuardians.length; g++) {
            if(accountGuardians[g] == guardian) {
                guardianFound = true;
                delete accountGuardians[g];
                emit GuardianRemoved(guardian);
            }
        }
        if(!guardianFound) {
            revert NotAGuardian(guardian);
        }
    }

    function getAllGuardians() external view onlyOwner returns(address[] memory){
        return accountGuardians;
    }
}