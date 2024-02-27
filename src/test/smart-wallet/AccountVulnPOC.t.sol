// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import "../utils/BaseTest.sol";
// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Target
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { AccountFactory, Account as SimpleAccount } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library GPv2EIP1271 {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
}

interface EIP1271Verifier {
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

/// @dev This is a dummy contract to test contract interactions with Account.
contract Number {
    uint256 public num;

    function setNum(uint256 _num) public {
        num = _num;
    }

    function doubleNum() public {
        num *= 2;
    }

    function incrementNum() public {
        num += 1;
    }

    function setNumBySignature(address owner, uint256 newNum, bytes calldata signature) public {
        if (owner.code.length == 0) {
            // Signature verification by ECDSA
        } else {
            // Signature verification by EIP1271
            bytes32 digest = keccak256(abi.encode(newNum));
            require(
                EIP1271Verifier(owner).isValidSignature(digest, signature) == GPv2EIP1271.MAGICVALUE,
                "GPv2: invalid eip1271 signature"
            );
            num = newNum;
        }
    }
}

contract SimpleAccountVulnPOCTest is BaseTest {
    // Target contracts
    EntryPoint private entrypoint;
    AccountFactory private accountFactory;

    // Mocks
    Number internal numberContract;

    // Test params
    uint256 private accountAdminPKey = 100;
    address private accountAdmin;

    uint256 private accountSignerPKey = 200;
    address private accountSigner;

    uint256 private nonSignerPKey = 300;
    address private nonSigner;

    // UserOp terminology: `sender` is the smart wallet.
    address private sender = 0x0df2C3523703d165Aa7fA1a552f3F0B56275DfC6;
    address payable private beneficiary = payable(address(0x45654));

    bytes32 private uidCache = bytes32("random uid");

    event AccountCreated(address indexed account, address indexed accountAdmin);

    function _prepareSignature(
        IAccountPermissions.SignerPermissionRequest memory _req
    ) internal view returns (bytes32 typedDataHash) {
        bytes32 typehashSignerPermissionRequest = keccak256(
            "SignerPermissionRequest(address signer,uint8 isAdmin,address[] approvedTargets,uint256 nativeTokenLimitPerTransaction,uint128 permissionStartTimestamp,uint128 permissionEndTimestamp,uint128 reqValidityStartTimestamp,uint128 reqValidityEndTimestamp,bytes32 uid)"
        );
        bytes32 nameHash = keccak256(bytes("Account"));
        bytes32 versionHash = keccak256(bytes("1"));
        bytes32 typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, sender));

        bytes memory encodedRequestStart = abi.encode(
            typehashSignerPermissionRequest,
            _req.signer,
            _req.isAdmin,
            keccak256(abi.encodePacked(_req.approvedTargets)),
            _req.nativeTokenLimitPerTransaction
        );

        bytes memory encodedRequestEnd = abi.encode(
            _req.permissionStartTimestamp,
            _req.permissionEndTimestamp,
            _req.reqValidityStartTimestamp,
            _req.reqValidityEndTimestamp,
            _req.uid
        );

        bytes32 structHash = keccak256(bytes.concat(encodedRequestStart, encodedRequestEnd));
        typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function _signSignerPermissionRequest(
        IAccountPermissions.SignerPermissionRequest memory _req
    ) internal view returns (bytes memory signature) {
        bytes32 typedDataHash = _prepareSignature(_req);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(accountAdminPKey, typedDataHash);
        signature = abi.encodePacked(r, s, v);
    }

    function _setupUserOp(
        uint256 _signerPKey,
        bytes memory _initCode,
        bytes memory _callDataForEntrypoint
    ) internal returns (UserOperation[] memory ops) {
        uint256 nonce = entrypoint.getNonce(sender, 0);

        // Get user op fields
        UserOperation memory op = UserOperation({
            sender: sender,
            nonce: nonce,
            initCode: _initCode,
            callData: _callDataForEntrypoint,
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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPKey, msgHash);
        bytes memory userOpSignature = abi.encodePacked(r, s, v);

        address recoveredSigner = ECDSA.recover(msgHash, v, r, s);
        address expectedSigner = vm.addr(_signerPKey);
        assertEq(recoveredSigner, expectedSigner);

        op.signature = userOpSignature;

        // Store UserOp
        ops = new UserOperation[](1);
        ops[0] = op;
    }

    function _setupUserOpExecute(
        uint256 _signerPKey,
        bytes memory _initCode,
        address _target,
        uint256 _value,
        bytes memory _callData
    ) internal returns (UserOperation[] memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            _target,
            _value,
            _callData
        );

        return _setupUserOp(_signerPKey, _initCode, callDataForEntrypoint);
    }

    function _setupUserOpExecuteBatch(
        uint256 _signerPKey,
        bytes memory _initCode,
        address[] memory _target,
        uint256[] memory _value,
        bytes[] memory _callData
    ) internal returns (UserOperation[] memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "executeBatch(address[],uint256[],bytes[])",
            _target,
            _value,
            _callData
        );

        return _setupUserOp(_signerPKey, _initCode, callDataForEntrypoint);
    }

    function setUp() public override {
        super.setUp();

        // Setup signers.
        accountAdmin = vm.addr(accountAdminPKey);
        vm.deal(accountAdmin, 100 ether);

        accountSigner = vm.addr(accountSignerPKey);
        nonSigner = vm.addr(nonSignerPKey);

        // Setup contracts
        entrypoint = new EntryPoint();
        // deploy account factory
        accountFactory = new AccountFactory(deployer, IEntryPoint(payable(address(entrypoint))));
        // deploy dummy contract
        numberContract = new Number();
    }

    /*//////////////////////////////////////////////////////////
                    Test: performing a contract call
    //////////////////////////////////////////////////////////////*/

    function _setup_executeTransaction() internal {
        bytes memory initCallData = abi.encodeWithSignature("createAccount(address,bytes)", accountAdmin, bytes(""));
        bytes memory initCode = abi.encodePacked(abi.encodePacked(address(accountFactory)), initCallData);

        UserOperation[] memory userOpCreateAccount = _setupUserOpExecute(
            accountAdminPKey,
            initCode,
            address(0),
            0,
            bytes("")
        );

        EntryPoint(entrypoint).handleOps(userOpCreateAccount, beneficiary);
    }

    function test_POC() public {
        _setup_executeTransaction();

        /*//////////////////////////////////////////////////////////
                                Setup
        //////////////////////////////////////////////////////////////*/
        address account = accountFactory.getAddress(accountAdmin, bytes(""));

        address[] memory approvedTargets = new address[](1);
        approvedTargets[0] = address(0x123); // allowing accountSigner permissions for some random contract, consider it as 0 address here

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            0,
            approvedTargets,
            1 ether,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig = _signSignerPermissionRequest(permissionsReq);
        IAccountPermissions(payable(account)).setPermissionsForSigner(permissionsReq, sig);

        // As expected, Account Signer is not be able to call setNum on numberContract since it doesnt have numberContract as approved target
        assertEq(numberContract.num(), 0);

        vm.prank(accountSigner);
        UserOperation[] memory userOp = _setupUserOpExecute(
            accountSignerPKey,
            bytes(""),
            address(numberContract),
            0,
            abi.encodeWithSignature("setNum(uint256)", 42)
        );

        vm.expectRevert();
        EntryPoint(entrypoint).handleOps(userOp, beneficiary);

        /*//////////////////////////////////////////////////////////
                                Attack
        //////////////////////////////////////////////////////////////*/

        // However they can bypass this by using signature verification on number contract instead
        vm.prank(accountSigner);
        bytes32 digest = keccak256(abi.encode(42));
        bytes32 toSign = SimpleAccount(payable(account)).getMessageHash(digest);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(accountSignerPKey, toSign);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Account: caller not approved target.");
        numberContract.setNumBySignature(account, 42, signature);
        assertEq(numberContract.num(), 0);

        // Signer can perform transaction if target is approved.
        address[] memory newApprovedTargets = new address[](2);
        newApprovedTargets[0] = address(0x123); // allowing accountSigner permissions for some random contract, consider it as 0 address here
        newApprovedTargets[1] = address(numberContract);

        IAccountPermissions.SignerPermissionRequest memory updatedPermissionsReq = IAccountPermissions
            .SignerPermissionRequest(
                accountSigner,
                0,
                newApprovedTargets,
                1 ether,
                0,
                type(uint128).max,
                0,
                type(uint128).max,
                bytes32("another UID")
            );

        vm.prank(accountAdmin);
        bytes memory sig2 = _signSignerPermissionRequest(updatedPermissionsReq);
        IAccountPermissions(payable(account)).setPermissionsForSigner(updatedPermissionsReq, sig2);

        numberContract.setNumBySignature(account, 42, signature);
        assertEq(numberContract.num(), 42);
    }
}
