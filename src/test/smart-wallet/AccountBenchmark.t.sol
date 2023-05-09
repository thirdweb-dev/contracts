// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";

import { EntryPoint, IEntryPoint } from "contracts/smart-wallet/utils/Entrypoint.sol";

import { UserOperation } from "contracts/smart-wallet/utils/UserOperation.sol";

import { AccountFactory } from "contracts/smart-wallet/non-upgradeable/AccountFactory.sol";

/// @dev This is a dummy contract to test the gas cost of performing transactions with Account.
contract Number {
    uint256 public num;

    function setNum(uint256 _num) public {
        num = _num;
    }
}

contract AccountBenchmarkTest is BaseTest {
    // Contracts
    address payable private entrypoint;
    AccountFactory private accountFactory;
    Number internal numberContract;

    // Test params
    uint256 private signerPrivateKey = 100;
    address private walletSigner;
    address private sender = 0xBB956D56140CA3f3060986586A2631922a4B347E;
    address payable private beneficiary = payable(address(0x45654));
    bytes private userOpSignature;

    // Test UserOps
    UserOperation[] private userOpCreateAccount;
    UserOperation[] private userOpPerformTx;

    function _encodeRequest(UserOperation memory _req, bytes32 _typehash) internal pure returns (bytes memory) {
        return
            abi.encode(
                _typehash,
                _req.sender,
                _req.nonce,
                keccak256(_req.initCode),
                keccak256(_req.callData),
                _req.callGasLimit,
                _req.verificationGasLimit,
                _req.preVerificationGas,
                _req.maxFeePerGas,
                _req.maxPriorityFeePerGas,
                keccak256(_req.paymasterAndData),
                keccak256(bytes("")) // A user signs a user op with an empty signature field
            );
    }

    function _getUserOpSignature(UserOperation memory op, uint256 _signerPKey)
        internal
        returns (bytes memory signature, bytes32 typedDataHash)
    {
        bytes32 typehashUserOp = keccak256(
            "UserOperation(address sender,uint256 nonce,bytes initCode,bytes callData,uint256 callGasLimit,uint256 verificationGasLimit,uint256 preVerificationGas,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,bytes paymasterAndData,bytes signature)"
        );
        bytes32 nameHash = keccak256(bytes("Account"));
        bytes32 versionHash = keccak256(bytes("1"));
        bytes32 typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, sender));

        bytes memory encodedRequest = _encodeRequest(op, typehashUserOp);
        bytes32 structHash = keccak256(encodedRequest);
        typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPKey, typedDataHash);
        signature = abi.encodePacked(r, s, v);
    }

    function _setupUserOp_performTx() private {
        // Get user op fields
        bytes memory subCallData = abi.encodeWithSignature("setNum(uint256)", 10);
        bytes memory callData = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            numberContract,
            0,
            subCallData
        );

        UserOperation memory op = UserOperation({
            sender: sender,
            nonce: 1,
            initCode: bytes(""),
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
        bytes memory userOpSignature;
        bytes32 typedDataHash;

        (userOpSignature, typedDataHash) = _getUserOpSignature(op, signerPrivateKey);

        address recoveredSigner = ECDSA.recover(typedDataHash, userOpSignature);
        address expectedSigner = vm.addr(signerPrivateKey);
        assertEq(recoveredSigner, expectedSigner);

        op.signature = userOpSignature;

        // Store UserOp
        userOpPerformTx.push(op);
    }

    function _setupUserOp_createAccount() private {
        // Get user op fields
        bytes memory subCallData = abi.encodeWithSignature("setNum(uint256)", 5);
        bytes memory callData = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            numberContract,
            0,
            subCallData
        );

        // build UserOp
        bytes memory initCallData = abi.encodeWithSignature("createAccount(address,bytes)", walletSigner, bytes(""));

        UserOperation memory op = UserOperation({
            sender: sender,
            nonce: 0,
            initCode: abi.encodePacked(abi.encodePacked(address(accountFactory)), initCallData),
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
        bytes memory userOpSignature;
        bytes32 typedDataHash;

        (userOpSignature, typedDataHash) = _getUserOpSignature(op, signerPrivateKey);

        address recoveredSigner = ECDSA.recover(typedDataHash, userOpSignature);
        address expectedSigner = vm.addr(signerPrivateKey);
        assertEq(recoveredSigner, expectedSigner);

        op.signature = userOpSignature;

        // Store UserOp
        userOpCreateAccount.push(op);
    }

    function setUp() public override {
        super.setUp();

        // Set wallet signer.
        walletSigner = vm.addr(signerPrivateKey);
        vm.deal(walletSigner, 100 ether);

        // deploy Entrypoint
        entrypoint = payable(address(new EntryPoint()));
        // deploy account factory
        accountFactory = new AccountFactory(IEntryPoint(entrypoint));
        // deploy dummy contract
        numberContract = new Number();

        _setupUserOp_createAccount();
        _setupUserOp_performTx();
    }

    /// @dev Create an account by directly calling the factory.
    function test_benchmark_createAccount_directWithFactory() public {
        accountFactory.createAccount(address(0x456), bytes(""));
    }

    /// @dev Create an account when performing the first transaction from the account (all via Entrypoint).
    function test_benchmark_createAccount_withUserOp() public {
        EntryPoint(entrypoint).handleOps(userOpCreateAccount, beneficiary);
    }

    /// @dev Perform a state changing transaction via EOA.
    function test_benchmark_dummyTx_withEOA() public {
        numberContract.setNum(20);
    }

    /// @dev Perform a state changing transaction via EOA.
    function test_benchmark_dummyTx_withAccount() public {
        EntryPoint(entrypoint).handleOps(userOpCreateAccount, beneficiary);
        EntryPoint(entrypoint).handleOps(userOpPerformTx, beneficiary);
    }
}
