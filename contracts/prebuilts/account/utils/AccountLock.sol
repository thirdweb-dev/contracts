// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import {IAccountLock} from "../interface/IAccountLock.sol";
import {Guardian} from "contracts/prebuilts/account/utils/Guardian.sol";
import {AccountGuardian} from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AccountLock is IAccountLock {
    Guardian public guardianContract;
    address internal _guardianInitiatingLockRequest = msg.sender; 
    address[] internal _lockedAccounts;
    mapping(address => bytes32) public accountToLockRequest;
    mapping(bytes32 => mapping(address => bytes)) public lockRequestToGuardianToSignature;
    mapping(bytes32 => mapping(address => bool)) lockRequestToGuardianToSignatureValid;
    
    constructor(Guardian _guardian) {
        guardianContract = _guardian;
    }
    
    /////////////////////////////////
    /////// External Func ///////////
    /////////////////////////////////

    function createLockRequest(address account) external returns(bytes32) {
        /**
         * Step 1: check if the msg.sender is the guardian of the smartWallet account
         * 
         * Step 2: Check the current status of the smart wallet (locked/unlocked) and if unlocked, check if any exisiting lock request exists. Revert if wallet is already locked or a lock req. exists
         * 
         * Step 3: Create lock request (Encode -> Hashing)
         * 
         * Step 4: Send request to all other guardians of this smart account
         **/ 

        address accountGuardian = guardianContract.getAccountGuardian(account);
        if(!AccountGuardian(accountGuardian).isAccountGuardian(_guardianInitiatingLockRequest)) {
            revert NotAGuardian(_guardianInitiatingLockRequest);
        }

        if(_isLocked(account)) {
            revert AccountAlreadyLocked(account);
        } 

        if(activeLockRequestExists(account)){
            revert ActiveLockRequestFound();
        }

        bytes32 lockRequestHash = keccak256(abi.encodePacked(
            "_lockRequest(address account)",
            _guardianInitiatingLockRequest,
            account
        ));

        accountToLockRequest[account] = lockRequestHash;
        return lockRequestHash;
    }

    function recordSignatureOnLockRequest(bytes32 lockRequest, bytes calldata signature) external {
        lockRequestToGuardianToSignature[lockRequest][msg.sender] = signature;
    }

    //TODO: Trigger to this function needs to be added
    function lockRequestAccepted(address account) external returns(bool) {
        uint256 validGuardianSignatures = 0;
        bytes32 lockRequest = accountToLockRequest[account];
        address accountGuardian = guardianContract.getAccountGuardian(account);
        address[] memory guardians = AccountGuardian(accountGuardian).getAllGuardians();
        uint256 guardianCount = guardians.length;

       for(uint256 g = 0; g < guardians.length; g++){
        address guardian = guardians[g];
        bytes memory guardianSignature = lockRequestToGuardianToSignature[lockRequest][guardian];
        // checking if this guardian has signed the request
        if(guardianSignature.length > 0) {
            address recoveredGuardian = _verifyLockRequestSignature(lockRequest, guardianSignature);

             if(recoveredGuardian == guardian) {
                lockRequestToGuardianToSignatureValid[lockRequest][guardian] = true;
                validGuardianSignatures++;
            } else {
                lockRequestToGuardianToSignatureValid[lockRequest][guardian] = false;
            }

            if(validGuardianSignatures > (guardianCount/2)) {
                return true;
            } else {
                return false;
            }
        }
        }
    }

    /////////////////////////////////
    /////// View Func //////////////
    ////////////////////////////////
    function activeLockRequestExists(address account) public view returns(bool) {
        if(accountToLockRequest[account].length > 0) {
            return true;
        } else {
            return false;
        }
    }
    
    /////////////////////////////////
    //// Internal Func /////////////
    /////////////////////////////////

    function _isLocked(address account) internal view returns(bool) {
        for(uint256 a = 0; a < _lockedAccounts.length; a++) {
            if(_lockedAccounts[a] == account) {
                return true;
            }
        }
        return false;
    }


    /**
     * @notice Will lock all account assets and transactions
     * @param account The account to be locked
     */
    function _lockAccount(address account) internal {}

     function _verifyLockRequestSignature(bytes32 lockRequest, bytes memory guardianSignature) internal returns(address) {
        // verify
        address recoveredGuardian = ECDSA.recover(lockRequest, guardianSignature);

        return recoveredGuardian;  
    }

}