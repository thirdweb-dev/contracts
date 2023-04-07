// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";

import { IEntryPoint } from "contracts/smart-wallet/interfaces/IEntryPoint.sol";
import { EntryPoint } from "contracts/smart-wallet/utils/EntryPoint.sol";

import { UserOperation } from "contracts/smart-wallet/utils/UserOperation.sol";

import { TWAccountFactory } from "contracts/smart-wallet/TWAccountFactory.sol";

contract Number {
    uint256 public num;

    function setNum(uint256 _num) public {
        num = _num;
    }
}

contract TWAccountBenchmarkTest is BaseTest {
    event SignerAddr(address signer);

    // Contracts
    address payable private entrypoint;
    TWAccountFactory private twAccountFactory;

    // Test params
    uint256 private signerPrivateKey = 100;
    address private walletSigner;
    address private sender = 0xB587D47Db9d58f9a49f367D260690fdE38A3D087;
    address payable private beneficiary = payable(address(0x45654));
    bytes private userOpSignature;

    // Test UserOps
    UserOperation[] private userOpCreateAccountOnly;

    event TestMsgHash(bytes32 msgHash);
    event TestOpHash(bytes32 opHash);

    function setUp() public override {
        super.setUp();

        // Set wallet signer.
        walletSigner = vm.addr(signerPrivateKey);

        // deploy Entrypoint
        entrypoint = payable(address(new EntryPoint()));
        // deploy account factory
        twAccountFactory = new TWAccountFactory(IEntryPoint(entrypoint));

        // Get user op fields
        bytes memory subCallData = abi.encodeWithSignature("setNum(uint256)", 5);
        bytes memory callData = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            address(new Number()),
            0,
            subCallData
        );

        // build UserOp
        bytes memory initCallData = abi.encodeWithSignature(
            "createAccount(address,bytes32)",
            walletSigner,
            keccak256("random-salt")
        );

        UserOperation memory op = UserOperation({
            sender: sender,
            nonce: 0,
            initCode: abi.encodePacked(abi.encodePacked(address(twAccountFactory)), initCallData),
            callData: callData,
            callGasLimit: 500_000,
            verificationGasLimit: 500_000,
            preVerificationGas: 500_000,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });

        // Sign UserOp

        bytes32 opHash = EntryPoint(entrypoint).getUserOpHash(op);
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(opHash);

        emit TestOpHash(opHash);
        emit TestMsgHash(msgHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, msgHash);
        userOpSignature = abi.encodePacked(r, s, v);

        address recoveredSigner = ECDSA.recover(msgHash, v, r, s);
        emit SignerAddr(recoveredSigner);

        op.signature = userOpSignature;

        // Store user op
        userOpCreateAccountOnly.push(op);

        // userOpCreateAccountOnly = new UserOperation(
        //     address(twAccountFactory),
        //     abi.encodeWithSignature("createAccount(address,bytes32)", address(0x123), keccak256("salt"))
        // );
    }

    function test_benchmark_createAccount() public {
        twAccountFactory.createAccount(address(0x456), keccak256("salt"));
    }

    function test_benchmark_createAccountWithUserOp() public {
        EntryPoint(entrypoint).handleOps(userOpCreateAccountOnly, beneficiary);
    }
}
