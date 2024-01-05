// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountRecovery {
    // Errors //
    error NotOwner(address sender);
    error NotAGuardian(address sender);
    error NoRecoveryRequestFound(address account);
    error NoSignaturesYet();
    error EmailVerificationFailed();
    error NotAuthorizedToCommitEmailVerificationHash(address sender);

    // Events //
    event AccountRecoveryRequestCreated();
    event GuardianSignatureRecorded(address indexed guardian);
    event AccountRecoveryRequestConcensusAchieved(address indexed account);
    event AccountRecoveryRequestConcensusFailed(address indexed account);
    event RestoredKeyEmailed();

    /**
     * @dev This function will be called from the Email verification service updating the user's recovery token & nounce hash.
     * Nonce is to make sure that the one token is being used only once.
     */
    function commitEmailVerificationHash(bytes32 emailVerificationHash) external;

    /**
     * @dev This function is used to generate the account recovery request.
     *
     * @param email The email associated with the recovery account
     *
     * @param recoveryToken The email recovery token used to prove the sender as the owner of the email
     *
     * @param recoveryTokenNonce The nonce is used to make sure that this particular recovery token is only used once. The nonce is incremented on creation of any new recovery token
     */
    function generateRecoveryRequest(
        string calldata email,
        bytes calldata recoveryToken,
        uint256 recoveryTokenNonce
    ) external;

    /**
     * @dev Retrieve the account's recovery request, if exists.
     * Only verified account guardians can call this function.
     */
    function getRecoveryRequest() external returns (bytes32);

    /**
     * @dev Will collect the guardians signatures on the account's active recovery request. With every signature, it will also check if concensus has been achieved. If concensus acheived, the updateAdmin() on the Smart Account will be called with the new admin to be updates as owner of that smart account, thus recovering the account.
     *
     * @param recoveryReqSignature The signature of the guardian on the account's active recovery req.
     *
     * @param guardian The guardian signing the account recovery request
     */
    function collectGuardianSignaturesOnRecoveryRequest(address guardian, bytes memory recoveryReqSignature) external;
}
