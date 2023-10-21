// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountLock {
     /*///////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/

    /**
     * An event emitted when account lock request is successfully created by a guardian.
     * @param smartWallet address of the smart wallet for which lock request is created
     */
    event AccountLockRequestCreated(address indexed smartWallet);

    /**
     * An event emitted when account unlock request is successfully created by a guardian.
     * @param smartWallet address of the smart wallet for which lock request is created
     */
    event AccountUnLockRequestCreated(address indexed smartWallet);

    /**
     * An event emitted when a guardian accepts a lock request.
     * @param lockRequest type hash of the lock request
     * @param guardian address of guardian who accepted the request
     */
    event AccountLockRequestAccepted(bytes32 indexed lockRequest, address indexed guardian);

    /**
     * @notice An event emitted when a guardian declines a lock request.
     * @param lockRequest type hash of the lock request
     * @param guardian address of guardian who accepted the request
     */
    event AccountLockRequestRejected(bytes32 indexed lockRequest, address indexed guardian);

     /*///////////////////////////////////////////////////////////////
                        Errors
    //////////////////////////////////////////////////////////////*/

    /**
     * This error is thrown when a non-guardian tries to create a recovery
     * request of a smart wallet account.
     * @param smartWallet address of the smart wallet being recovered
     */
    error NotAGuardian(address smartWallet);

    /**
     * Error thrown when a unlock request is created for an already unlocked smart-wallet
     * @param smartWallet address of the smart wallet being unlocked
     */
    error AccountAlreadyUnlocked(address smartWallet);

     /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Triggered by a guardian to create a lock request.
     * @param smartWallet address of the smart wallet to be recovered
     */

    function createLockRequest(address smartWallet) external returns(bytes memory);

    /**
     * @dev This function is called when a guardian makes his choice of 
     * signing or not signing the account lock request.
     * @param lockRequest type hash of the lock request
     * @return Request signature incase the guardian accepts the request else returns null.
     */

    function acceptOrRejectLockRequest(bytes32 lockRequest) external returns(bytes memory);

    /**
     * @dev Triggered by a guardian to create an unlock request.
     * @param smartWallet address of the smart wallet to be unlocked
     */

    function createUnLockRequest(address smartWallet) external returns(bytes memory);

    /**
     * @dev This function is called when a guardian makes his choice of 
     * signing or not signing the account unlocking request.
     * @param unlockRequest type hash of the unlock request
     * @return Request signature incase the guardian accepts the request else returns null.
     */
    function acceptOrRejectUnlockRequest(bytes32 unlockRequest) external returns(bytes memory);

}