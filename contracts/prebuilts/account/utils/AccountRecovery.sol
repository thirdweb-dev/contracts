// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IAccountRecovery } from "../interface/IAccountRecovery.sol";
import { AccountGuardian } from "./AccountGuardian.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AccountRecovery is IAccountRecovery {
    address public immutable account;
    address public immutable owner;
    address public immutable accountGuardian;
    address[] public accountGuardians;
    bytes32 public accountRecoveryRequest;
    address[] public guardiansWhoSigned;
    mapping(address => uint8) private shards;
    mapping(address => bytes) private guardianSignatures;

    constructor(address _account, address _accountGuardian) {
        owner = msg.sender;
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

    function storePrivateKeyShards(uint8[] calldata privateKeyShards) external onlyOwner {
        accountGuardians = AccountGuardian(accountGuardian).getAllGuardians();

        require(
            privateKeyShards.length == accountGuardians.length,
            "Mismatch between no. of shards & account guardians"
        );

        for (uint256 s = 0; s < privateKeyShards.length; s++) {
            shards[accountGuardians[s]] = privateKeyShards[s]; // alloting shards to each guardian
        }
        emit PrivateKeyShardsAlloted();
        //TODO: shards should be store in a more secure, decentralized storage service instead of contract state
    }

    function generateRecoveryRequest() external onlyVerifiedAccountGuardian {
        bytes32 restoreKeyRequestHash = keccak256(abi.encodeWithSignature("restorePrivateKey()"));

        accountRecoveryRequest = ECDSA.toEthSignedMessageHash(restoreKeyRequestHash);

        emit AccountRecoveryRequestCreated(account);
    }

    function getRecoveryRequest() public view onlyVerifiedAccountGuardian returns (bytes32) {
        return accountRecoveryRequest;
    }

    function collectGuardianSignaturesOnRecoveryRequest(
        address guardian,
        bytes memory recoveryReqSignature
    ) external override onlyVerifiedAccountGuardian {
        if (accountRecoveryRequest == bytes32(0)) {
            revert NoRecoveryRequestFound(account);
        }

        guardiansWhoSigned.push(guardian);
        guardianSignatures[guardian] = recoveryReqSignature;
        emit GuardianSignatureRecorded(guardian);
    }

    function restorePrivateKey() external override onlyVerifiedAccountGuardian {
        require(_accountRecoveryConcensusEvaluation(), "Account Recovery Concensus has to be achieved!");

        bytes memory restoredPrivateKey;
        for (uint256 g = 0; g < guardiansWhoSigned.length; g++) {
            restoredPrivateKey = abi.encodePacked(restoredPrivateKey, shards[guardiansWhoSigned[g]]);
        }

        emit RestoredKeyEmailed();
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
        bytes32 request;
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

        // accountRequestConcensusEvaluationStatus[request] = true;

        if (validGuardianSignatures > (guardianCount / 2)) {
            emit AccountRecoveryRequestConcensusAchieved(account);
            return true;
        } else {
            emit AccountRecoveryRequestConcensusFailed(account);
            return false;
        }
    }
}
