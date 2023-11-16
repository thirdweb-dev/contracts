//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IGuardian } from "../interface/IGuardian.sol";

contract Guardian is IGuardian {
    address[] private verifiedGuardians;
    address public owner;
    mapping(address => address) private accountToAccountGuardian;
    mapping(address => address[]) private guardianToAccounts;

    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function addVerifiedGuardian() external {
        address guardian = msg.sender;
        require(guardian != address(0), "Cannot be a zero address");

        for (uint256 g = 0; g < verifiedGuardians.length; g++) {
            if (verifiedGuardians[g] == guardian) {
                revert GuardianAlreadyExists(guardian);
            }
        }
        emit GuardianAdded(guardian);
        verifiedGuardians.push(guardian);
    }

    function isVerifiedGuardian(address isVerified) public view returns (bool) {
        require(isVerified != address(0), "Guardian address cannot be a zero address");

        for (uint256 g = 0; g < verifiedGuardians.length; g++) {
            if (verifiedGuardians[g] == isVerified) {
                return true;
            }
        }
        return false;
    }

    function removeVerifiedGuardian() external {
        address guardian = msg.sender;
        bool guardianFound = false;

        for (uint256 g = 0; g < verifiedGuardians.length; g++) {
            if (verifiedGuardians[g] == guardian) {
                // remove the guardian
                guardianFound = true;
                delete verifiedGuardians[g];
                emit GuardianRemoved(guardian);
            }
        }
        if (!guardianFound) {
            revert NotAGuardian(guardian);
        }
    }

    function linkAccountToAccountGuardian(address account, address accountGuardian) external {
        accountToAccountGuardian[account] = accountGuardian;
    }

    function addAccountToGuardian(address guardian, address account) external {
        guardianToAccounts[guardian].push(account);
    }

    ///////////////////////////////
    ///// Getter Functions ///////
    ///////////////////////////////

    function getVerifiedGuardians() external view onlyOwner returns (address[] memory) {
        return verifiedGuardians;
    }

    function getAccountGuardian(address account) external view returns (address) {
        return accountToAccountGuardian[account];
    }

    // TODO: Refactor this functions with the POV of access modifiers
    function getAccountsTheGuardianIsGuarding(address guardian) external view returns (address[] memory) {
        if (!isVerifiedGuardian(guardian)) {
            revert NotAGuardian(guardian);
        }

        return guardianToAccounts[guardian];
    }
}
