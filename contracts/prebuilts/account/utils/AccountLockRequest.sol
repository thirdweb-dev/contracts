// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import {IAccountLockRequest} from "../interface/IAccountLockRequest.sol";

abstract contract AccountLockRequest is IAccountLockRequest {
    
    function createLockRequest(address smartWallet) external returns(bytes memory) {
        /**
         * Step 1: check if the msg.sender is the guardian of the smartWallet account
         * 
         * Step 2: Check the current status of the smart wallet (locked/unlocked) and revert if wallet is already locked
         * 
         * Step 3: Create lock request
         * 
         * Step 4: Send request to all other guardians of this smart account
         * */ 
    } 
}