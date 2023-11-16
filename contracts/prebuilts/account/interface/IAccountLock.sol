// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountLock {
    /*///////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/

    /**
     * An event emitted when account lock request is successfully created by a guardian.
     * @param account address of the smart wallet for which lock request is created
     */
    event AccountLockRequestCreated(address indexed account);

    /**
     * An event emitted when account unlock request is successfully created by a guardian.
     * @param account address of the smart wallet for which lock request is created
     */
    event AccountUnLockRequestCreated(address indexed account);

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
     * Error returned when guardian trying to send lock request for account which doesn't have a lock req. created
     * @param account Account whose lock req. has to be send to it's guardians
     */
    error NoLockRequestFound(address account);

    /**
     * This error is thrown when a non-guardian tries to create a recovery
     * request of a smart wallet account.
     * @param sender address of the caller
     */
    error NotAGuardian(address sender);

    /**
     * Error thrown when a lock request is created for an already locked smart-wallet
     * @param account address of the smart wallet being unlocked
     */
    error AccountAlreadyLocked(address account);

    /**
     * Error returned when creating a account lock request for which lock reques already exists.
     */
    error ActiveLockRequestFound();

    /**
     * Error thrown when trying to evaluate concensys for lock request that is not connected to the account sent
     * @param account account whose lock req concensys is being evaluated
     */
    error AccountLockRequestNotFound(address account);

    /**
     * Error thrown when a unlock request is created for an already unlocked smart-wallet
     * @param account address of the smart wallet being unlocked
     */
    error AccountAlreadyUnlocked(address account);

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Triggered by a guardian to create a lock request.
     * @param account address of the smart wallet to be recovered
     */

    function createLockRequest(address account) external returns (bytes32);

    /**
     * @notice Records guardian's signature on a lock request by
     * updating `lockRequestToGuardianToSignature` mapping
     * @param lockRequest Lock request of an account
     * @param signature Guardian's signature on the lock request
     */
    function recordSignatureOnLockRequest(bytes32 lockRequest, bytes calldata signature) external;

    /**
     * @dev This function is used to evaluate if the lockRequest was accepted or rejected by the guardians.
     * @param account Account to which the lock request belongs.
     */

    function lockRequestConcensysEvaluation(address account) external returns (bool);

    /**
     * Will be called to execute the lock request on an account
     * @param account account to be locked
     */
    // function executeLockRequest(address account) external;

    /**
     * @dev Triggered by a guardian to create an unlock request.
     * @param account address of the smart wallet to be unlocked
     */

    // function createUnLockRequest(address account) external returns(bytes memory);

    /**
     * @dev This function is called when a guardian makes his choice of
     * signing or not signing the account unlocking request.
     * @param unlockRequest type hash of the unlock request
     * @return Request signature incase the guardian accepts the request else returns null.
     */
    // function unlockRequestAccepted(bytes32 unlockRequest) external returns(bytes memory);

    /*///////////////////////////////////////////////////////////////
                        View Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns a bool indicating if a lock request for the account already exists
     * @param account Account for which active lock request has to be checked
     */
    function activeLockRequestExists(address account) external view returns (bool);

    /**
     * @notice Returns all the lock request of a guardian
     */
    function getLockRequests() external view returns (bytes32[] memory);
}
