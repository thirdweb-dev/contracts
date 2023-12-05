// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { IAccountRecovery } from "../interface/IAccountRecovery.sol";
import { AccountGuardian } from "./AccountGuardian.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AccountRecovery is IAccountRecovery {
    mapping(address => uint8) private shards;
    address public immutable account;
    address public immutable owner;
    address public immutable accountGuardian;
    address[] public accountGuardians;
    bytes32 public restorePrivateKeyRequest;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    constructor(address _account, address _accountGuardian) {
        owner = msg.sender;
        account = _account;
        accountGuardian = _accountGuardian;
    }

    function storePrivateKeyShards(uint8[] calldata privateKeyShards) external onlyOwner {
        accountGuardians = AccountGuardian(accountGuardian).getAllGuardians();

        require(
            privateKeyShards.length == accountGuardians.length,
            "Mismatch between no. of shards & no. of account guardians"
        );

        for (uint256 s = 0; s < privateKeyShards.length; s++) {
            shards[accountGuardians[s]] = privateKeyShards[s];
        }
        //TODO: shards should be store in a more secure, decentralized storage service instead of contract state
    }

    function generateRecoveryRequest() external {
        bytes32 restoreKeyRequestHash = keccak256(abi.encodeWithSignature("restorePrivateKey()"));

        restorePrivateKeyRequest = ECDSA.toEthSignedMessageHash(restoreKeyRequestHash);
    }

    function getRecoveryRequest() public view returns (bytes32) {
        return restorePrivateKeyRequest;
    }

    function generateAndSendRecoveryRequest() external override {}

    function collectGuardianSignaturesOnRecoveryRequest(bytes memory recoveryReqSignature) external override {}

    function recoveryRequestConsensusEvaluation() external override returns (bool) {}

    function restorePrivateKey() external override returns (bytes memory) {}
}
