// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IAccountRecovery {
    // Errors //
    error NotOwner(address sender);

    /**
     * @dev Will be used to store the shards of user's private key in a secure cloud based storage of the user.
     * @param privateKeyShards Array of private key shards of the user's account
     */
    function storePrivateKeyShards(uint8[] calldata privateKeyShards) external;

    /**
     * @dev Create a account recovery request for the account.
     */

    function generateAndSendRecoveryRequest() external;

    /**
     * @dev Will collect the guardians signatures on the account's active recovery request
     * @param recoveryReqSignature The signature of the guardian on the account's active recovery req.
     */
    function collectGuardianSignaturesOnRecoveryRequest(bytes memory recoveryReqSignature) external;

    /**
     * @dev Will contain the evaluation logic for concensus of account recovery request by the guardians
     * @return Boolean flag indicating if the concensus on account recovery was achieved or not
     */
    function recoveryRequestConsensusEvaluation() external returns (bool);

    /**
     * @dev Will restore the private key, encrypt and return/email the user
     * @return Encrypted private key of the account
     */
    function restorePrivateKey() external returns (bytes memory);
}
