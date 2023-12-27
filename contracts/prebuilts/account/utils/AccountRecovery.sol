// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IAccountRecovery } from "../interface/IAccountRecovery.sol";
import { AccountGuardian } from "./AccountGuardian.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AccountRecovery is IAccountRecovery {
    address public immutable account;
    address public immutable owner;
    string private recoveryEmail;
    address private immutable emailVerificationServiceAddress; // The address of the email verification service, responsible for providing the emailVerificationHash
    bytes32 private emailVerificationHash;
    address public immutable accountGuardian;
    address[] public accountGuardians;
    bytes32 public accountRecoveryRequest;
    address[] public guardiansWhoSigned;
    address public newAdmin;
    mapping(address => bytes) private guardianSignatures;

    constructor(
        address _account,
        address _emailVerificationServiceAddress,
        string memory _recoveryEmail,
        address _accountGuardian
    ) {
        owner = msg.sender;
        emailVerificationServiceAddress = _emailVerificationServiceAddress;
        recoveryEmail = _recoveryEmail;
        account = _account;
        accountGuardian = _accountGuardian;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    modifier onlyVerifiedAccountGuardian() {
        if (!AccountGuardian(accountGuardian).isAccountGuardian(msg.sender)) {
            revert NotAGuardian(msg.sender);
        }
        _;
    }

    modifier onlyEmailVerificationService() {
        if (msg.sender != emailVerificationServiceAddress)
            revert NotAuthorizedToCommitEmailVerificationHash(msg.sender);
        _;
    }

    function commitRecoveryHash(bytes32 recoveryHash) external onlyEmailVerificationService {
        emailVerificationHash = recoveryHash;
    }

    function generateRecoveryRequest(
        string memory email,
        string calldata recoveryToken,
        string calldata recoveryTokenNonce
    ) external {
        bool isVerifiedToRecover = _verifyUserAsOwnerOfTheAccount(email, recoveryToken, recoveryTokenNonce);

        if (!isVerifiedToRecover) {
            revert NotOwner(msg.sender);
        }

        newAdmin = msg.sender;

        bytes32 restoreKeyRequestHash = keccak256(
            abi.encodeWithSignature("updateAdmin(address newAdmin, bytes memory email)", newAdmin, abi.encode(email))
        );

        accountRecoveryRequest = ECDSA.toEthSignedMessageHash(restoreKeyRequestHash);

        emit AccountRecoveryRequestCreated(account);
    }

    function collectGuardianSignaturesOnRecoveryRequest(
        address guardian,
        bytes memory recoveryReqSignature
    ) external onlyVerifiedAccountGuardian {
        if (accountRecoveryRequest == bytes32(0)) {
            revert NoRecoveryRequestFound(account);
        }

        guardiansWhoSigned.push(guardian);
        guardianSignatures[guardian] = recoveryReqSignature;
        emit GuardianSignatureRecorded(guardian);

        bool consensusAcheived = _accountRecoveryConcensusEvaluation();

        if (consensusAcheived) {
            (bool success, ) = (payable(account)).call(
                abi.encodeWithSignature(
                    "updateAdmin(address newAdmin, bytes memory _data)",
                    newAdmin,
                    abi.encode(recoveryEmail)
                )
            );

            require(success, "Failed to update Admin");
        }
    }

    // view function //
    function getRecoveryRequest() external returns (bytes32) {
        return accountRecoveryRequest;
    }

    // internal functions //

    function _recoverSigner(bytes memory guardianSignature) internal view returns (address) {
        // verify
        address recoveredGuardian = ECDSA.recover(accountRecoveryRequest, guardianSignature);

        return recoveredGuardian;
    }

    /**
     * @dev Will contain the evaluation logic for concensus of account recovery request by the guardians
     * @return Boolean flag indicating if the concensus on account recovery was achieved or not
     */

    function _accountRecoveryConcensusEvaluation() internal returns (bool) {
        uint256 guardianCount = AccountGuardian(accountGuardian).getAllGuardians().length;

        if (accountRecoveryRequest == bytes32(0)) {
            revert NoRecoveryRequestFound(account);
        }

        if (guardiansWhoSigned.length > 0) {
            revert NoSignaturesYet();
        }

        uint256 validGuardianSignatures = 0;

        for (uint256 g = 0; g < guardiansWhoSigned.length; g++) {
            address guardian = guardiansWhoSigned[g];
            bytes memory guardianSignature;

            guardianSignature = guardianSignatures[guardian];

            address recoveredGuardian = _recoverSigner(guardianSignature);

            if (recoveredGuardian == guardian) {
                validGuardianSignatures++;
            }
        }

        if (validGuardianSignatures > (guardianCount / 2)) {
            // accountRequestConcensusEvaluationStatus[request] = true;
            emit AccountRecoveryRequestConcensusAchieved(account);
            return true;
        } else {
            emit AccountRecoveryRequestConcensusFailed(account);
            return false;
        }
    }

    /**
     * @dev These conditions have to be met for a sender to prove ownership of the account being recovered:
     * 1. Email is associated with the smart account.
     * 2. EMail is owned by the sender
     */
    function _verifyUserAsOwnerOfTheAccount(
        string memory email,
        string calldata token,
        string calldata nonce
    ) internal returns (bool) {
        if (keccak256(abi.encodePacked(email)) == keccak256(abi.encodePacked(recoveryEmail))) {
            revert("Email does not match the recovery email of the smart account being recovered");
            return false;
        }

        bytes32 generatedEmailVerificationHash = keccak256(abi.encodePacked(token, nonce));
        if (generatedEmailVerificationHash != emailVerificationHash) {
            revert EmailVerificationFailed();
            return false;
        }
        return true;
    }
}
