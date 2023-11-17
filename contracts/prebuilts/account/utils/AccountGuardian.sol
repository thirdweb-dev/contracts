// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IAccountGuardian } from "../interface/IAccountGuardian.sol";
import { Guardian } from "./Guardian.sol";
import { AccountLock } from "./AccountLock.sol";

contract AccountGuardian is IAccountGuardian {
    Guardian public guardianContract;
    AccountLock public accountLock;
    address account;
    address[] private accountGuardians;
    address public owner;

    error NotOwnerOrAccountLock(address owner, address sender);

    constructor(Guardian _guardianContract, AccountLock _accountLock, address _account) {
        guardianContract = _guardianContract;
        accountLock = _accountLock;
        account = _account;
        owner = account;
    }

    modifier onlyOwnerOrAccountLock() {
        if (msg.sender != owner && msg.sender != address(accountLock)) {
            revert NotOwnerOrAccountLock(owner, msg.sender);
        }
        _;
    }

    ////////////////////////////
    ///// External Functions////
    ////////////////////////////

    function addGuardian(address guardian) external onlyOwnerOrAccountLock {
        if (guardianContract.isVerifiedGuardian(guardian)) {
            accountGuardians.push(guardian);
            guardianContract.addAccountToGuardian(guardian, owner);
            emit GuardianAdded(guardian);
        } else {
            revert GuardianNotVerified(guardian);
        }
    }

    function removeGuardian(address guardian) external onlyOwnerOrAccountLock {
        bool guardianFound = false;
        for (uint256 g = 0; g < accountGuardians.length; g++) {
            if (accountGuardians[g] == guardian) {
                guardianFound = true;
                delete accountGuardians[g];
                emit GuardianRemoved(guardian);
            }
        }
        if (!guardianFound) {
            revert NotAGuardian(guardian);
        }
    }

    function getAllGuardians() external view onlyOwnerOrAccountLock returns (address[] memory) {
        return accountGuardians;
    }

    function isAccountGuardian(address guardian) external view onlyOwnerOrAccountLock returns (bool) {
        for (uint256 g = 0; g < accountGuardians.length; g++) {
            if (accountGuardians[g] == guardian) {
                return true;
            }
        }
        return false;
    }
}