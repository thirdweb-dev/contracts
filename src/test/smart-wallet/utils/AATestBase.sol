pragma solidity ^0.8.0;

import { IEntryPoint } from "contracts/prebuilts/account/interface/IEntrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";
import { IAccount } from "contracts/prebuilts/account/interface/IAccount.sol";
import { VERIFYINGPAYMASTER_BYTECODE, VERIFYINGPAYMASTER_ADDRESS, ENTRYPOINT_0_6_BYTECODE, CREATOR_0_6_BYTECODE } from "./AATestArtifacts.sol";

import "contracts/external-deps/openzeppelin/utils/cryptography/ECDSA.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import { MockERC20 } from "../../mocks/MockERC20.sol";

interface IVerifyingPaymaster {
    function owner() external view returns (address);

    function getHash(
        UserOperation calldata userOp,
        uint48 validUntil,
        uint48 validAfter
    ) external view returns (bytes32);
}

interface VmModified {
    function cool(address _target) external;

    function keyExists(string calldata, string calldata) external returns (bool);

    function parseJsonKeys(string calldata json, string calldata key) external pure returns (string[] memory keys);
}

uint256 constant OV_FIXED = 21000;
uint256 constant OV_PER_USEROP = 18300;
uint256 constant OV_PER_WORD = 4;
uint256 constant OV_PER_ZERO_BYTE = 4;
uint256 constant OV_PER_NONZERO_BYTE = 16;

abstract contract AAGasProfileBase is Test {
    string public name;
    string public scenarioName;
    uint256 sum;
    string jsonObj;
    IEntryPoint public entryPoint;
    address payable public beneficiary;
    IAccount public account;
    address public owner;
    uint256 public key;
    IVerifyingPaymaster public paymaster;
    address public verifier;
    uint256 public verifierKey;
    bool public writeGasProfile = false;

    function(UserOperation memory) internal view returns (bytes memory) paymasterData;
    function(UserOperation memory) internal view returns (bytes memory) dummyPaymasterData;

    function initializeTest(string memory _name) internal {
        writeGasProfile = vm.envOr("WRITE_GAS_PROFILE", false);
        name = _name;
        entryPoint = IEntryPoint(payable(address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)));
        vm.etch(address(entryPoint), ENTRYPOINT_0_6_BYTECODE);
        vm.etch(0x7fc98430eAEdbb6070B35B39D798725049088348, CREATOR_0_6_BYTECODE);
        beneficiary = payable(makeAddr("beneficiary"));
        vm.deal(beneficiary, 1e18);
        paymasterData = emptyPaymasterAndData;
        dummyPaymasterData = emptyPaymasterAndData;
        (verifier, verifierKey) = makeAddrAndKey("VERIFIER");
        paymaster = IVerifyingPaymaster(VERIFYINGPAYMASTER_ADDRESS);
        vm.etch(address(paymaster), VERIFYINGPAYMASTER_BYTECODE);
        vm.store(address(paymaster), bytes32(0), bytes32(uint256(uint160(verifier))));
    }

    function setAccount() internal {
        (owner, key) = makeAddrAndKey("Owner");
        account = getAccountAddr(owner);
        vm.deal(address(account), 1e18);
    }

    function fillUserOp(bytes memory _data) internal view returns (UserOperation memory op) {
        op.sender = address(account);
        op.nonce = entryPoint.getNonce(address(account), 0);
        if (address(account).code.length == 0) {
            op.initCode = getInitCode(owner);
        }
        op.callData = _data;
        op.callGasLimit = 1000000;
        op.verificationGasLimit = 1000000;
        op.preVerificationGas = 21000;
        op.maxFeePerGas = 1;
        op.maxPriorityFeePerGas = 1;
        op.signature = getDummySig(op);
        op.paymasterAndData = dummyPaymasterData(op);
        op.preVerificationGas = calculatePreVerificationGas(op);
        op.paymasterAndData = paymasterData(op);
        op.signature = getSignature(op);
    }

    function signUserOpHash(uint256 _key, UserOperation memory _op) internal view returns (bytes memory signature) {
        bytes32 hash = entryPoint.getUserOpHash(_op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, ECDSA.toEthSignedMessageHash(hash));
        signature = abi.encodePacked(r, s, v);
    }

    function executeUserOp(UserOperation memory _op, string memory _test, uint256 _value) internal {
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _op;
        uint256 eth_before;
        if (_op.paymasterAndData.length > 0) {
            eth_before = entryPoint.balanceOf(address(paymaster));
        } else {
            eth_before = entryPoint.balanceOf(address(account)) + address(account).balance;
        }
        // vm.cool to be introduced to foundry
        //VmModified(address(vm)).cool(address(entryPoint));
        //VmModified(address(vm)).cool(address(account));
        entryPoint.handleOps(ops, beneficiary);
        uint256 eth_after;
        if (_op.paymasterAndData.length > 0) {
            eth_after = entryPoint.balanceOf(address(paymaster));
        } else {
            eth_after = entryPoint.balanceOf(address(account)) + address(account).balance + _value;
        }
        if (!writeGasProfile) {
            console.log("case - %s", _test);
            console.log("  gasUsed       : ", eth_before - eth_after);
            console.log("  calldatacost  : ", calldataCost(pack(_op)));
        }
        if (writeGasProfile && bytes(scenarioName).length > 0) {
            uint256 gasUsed = eth_before - eth_after;
            vm.serializeUint(jsonObj, _test, gasUsed);
            sum += gasUsed;
        }
    }

    function testCreation() internal {
        UserOperation memory op = fillUserOp(fillData(address(0), 0, ""));
        executeUserOp(op, "creation", 0);
    }

    function testTransferNative(address _recipient, uint256 _amount) internal {
        vm.skip(writeGasProfile);
        createAccount(owner);
        _amount = bound(_amount, 1, address(account).balance / 2);
        UserOperation memory op = fillUserOp(fillData(_recipient, _amount, ""));
        executeUserOp(op, "native", _amount);
    }

    function testTransferNative() internal {
        createAccount(owner);
        uint256 amount = 5e17;
        address recipient = makeAddr("recipient");
        UserOperation memory op = fillUserOp(fillData(recipient, amount, ""));
        executeUserOp(op, "native", amount);
    }

    function testTransferERC20() internal {
        createAccount(owner);
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.mint(address(account), 1e18);
        uint256 amount = 5e17;
        address recipient = makeAddr("recipient");
        uint256 balance = mockERC20.balanceOf(recipient);
        UserOperation memory op = fillUserOp(
            fillData(address(mockERC20), 0, abi.encodeWithSelector(mockERC20.transfer.selector, recipient, amount))
        );
        executeUserOp(op, "erc20", 0);
        assertEq(mockERC20.balanceOf(recipient), balance + amount);
    }

    function testBenchmark1Vanila() external {
        scenarioName = "vanila";
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
        testCreation();
        testTransferNative();
        testTransferERC20();
        if (writeGasProfile) {
            string memory res = vm.serializeUint(jsonObj, "sum", sum);
            console.log(res);
            vm.writeJson(res, string.concat("./results/", scenarioName, "_", name, ".json"));
        }
    }

    function testBenchmark2Paymaster() external {
        scenarioName = "paymaster";
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
        entryPoint.depositTo{ value: 100e18 }(address(paymaster));
        paymasterData = validatePaymasterAndData;
        dummyPaymasterData = getDummyPaymasterAndData;
        testCreation();
        testTransferNative();
        testTransferERC20();
        if (writeGasProfile) {
            string memory res = vm.serializeUint(jsonObj, "sum", sum);
            console.log(res);
            vm.writeJson(res, string.concat("./results/", scenarioName, "_", name, ".json"));
        }
    }

    function testBenchmark3Deposit() external {
        scenarioName = "deposit";
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
        entryPoint.depositTo{ value: 100e18 }(address(account));
        testCreation();
        testTransferNative();
        testTransferERC20();
        if (writeGasProfile) {
            string memory res = vm.serializeUint(jsonObj, "sum", sum);
            console.log(res);
            vm.writeJson(res, string.concat("./results/", scenarioName, "_", name, ".json"));
        }
    }

    function emptyPaymasterAndData(UserOperation memory _op) internal pure returns (bytes memory ret) {}

    function validatePaymasterAndData(UserOperation memory _op) internal view returns (bytes memory ret) {
        bytes32 hash = paymaster.getHash(_op, 0, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierKey, ECDSA.toEthSignedMessageHash(hash));
        ret = abi.encodePacked(address(paymaster), uint256(0), uint256(0), r, s, uint8(v));
    }

    function getDummyPaymasterAndData(UserOperation memory _op) internal view returns (bytes memory ret) {
        ret = abi.encodePacked(
            address(paymaster),
            uint256(0),
            uint256(0),
            hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"
        );
    }

    function pack(UserOperation memory _op) internal pure returns (bytes memory) {
        bytes memory packed = abi.encode(
            _op.sender,
            _op.nonce,
            _op.initCode,
            _op.callData,
            _op.callGasLimit,
            _op.verificationGasLimit,
            _op.preVerificationGas,
            _op.maxFeePerGas,
            _op.maxPriorityFeePerGas,
            _op.paymasterAndData,
            _op.signature
        );
        return packed;
    }

    function calldataCost(bytes memory packed) internal view returns (uint256) {
        uint256 cost = 0;
        for (uint256 i = 0; i < packed.length; i++) {
            if (packed[i] == 0) {
                cost += OV_PER_ZERO_BYTE;
            } else {
                cost += OV_PER_NONZERO_BYTE;
            }
        }
        return cost;
    }

    // NOTE: this can vary depending on the bundler, this equation is referencing eth-infinitism bundler's pvg calculation
    function calculatePreVerificationGas(UserOperation memory _op) internal view returns (uint256) {
        bytes memory packed = pack(_op);
        uint256 calculated = OV_FIXED + OV_PER_USEROP + (OV_PER_WORD * (packed.length + 31)) / 32;
        calculated += calldataCost(packed);
        return calculated;
    }

    function createAccount(address _owner) internal virtual;

    function getSignature(UserOperation memory _op) internal view virtual returns (bytes memory);

    function getDummySig(UserOperation memory _op) internal pure virtual returns (bytes memory);

    function fillData(address _to, uint256 _amount, bytes memory _data) internal view virtual returns (bytes memory);

    function getAccountAddr(address _owner) internal view virtual returns (IAccount _account);

    function getInitCode(address _owner) internal view virtual returns (bytes memory);
}
