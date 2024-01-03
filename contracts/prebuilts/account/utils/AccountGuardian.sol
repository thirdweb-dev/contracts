// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IAccountGuardian } from "../interface/IAccountGuardian.sol";
import { Guardian } from "./Guardian.sol";
import { AccountLock } from "./AccountLock.sol";
import { AccountRecovery } from "./AccountRecovery.sol";

contract AccountGuardian is IAccountGuardian {
    Guardian public guardianContract;
    AccountLock public accountLock;
    AccountRecovery public accountRecovery;
    address payable account;
    address[] private accountGuardians;
    address public owner;

    error NotAuthorized(address sender);

    constructor(
        Guardian _guardianContract,
        AccountLock _accountLock,
        address payable _account,
        address _emailService,
        string memory _recoveryEmail
    ) {
        guardianContract = _guardianContract;
        accountLock = _accountLock;
        account = _account;
        owner = account;
        accountRecovery = new AccountRecovery(account, _emailService, _recoveryEmail, address(this));
        guardianContract.linkAccountToAccountRecovery(account, address(accountRecovery));
    }

    modifier onlyOwnerAccountLockAccountRecovery() {
        if (msg.sender != owner && msg.sender != address(accountLock) && msg.sender != address(accountRecovery)) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    ////////////////////////////
    ///// External Functions////
    ////////////////////////////

    function addGuardian(address guardian) external onlyOwnerAccountLockAccountRecovery {
        if (guardianContract.isVerifiedGuardian(guardian)) {
            accountGuardians.push(guardian);
            guardianContract.addAccountToGuardian(guardian, owner);
            emit GuardianAdded(guardian);
        } else {
            revert GuardianNotVerified(guardian);
        }
    }

    function removeGuardian(address guardian) external onlyOwnerAccountLockAccountRecovery {
        require(guardian != address(0), "guardian address being removed cannot be a zero address");

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

    function getAllGuardians() external view onlyOwnerAccountLockAccountRecovery returns (address[] memory) {
        return accountGuardians;
    }

    function isAccountGuardian(address guardian) external view onlyOwnerAccountLockAccountRecovery returns (bool) {
        for (uint256 g = 0; g < accountGuardians.length; g++) {
            if (accountGuardians[g] == guardian) {
                return true;
            }
        }
        return false;
    }

    function getTotalGuardians() external view override returns (uint256) {}
}
