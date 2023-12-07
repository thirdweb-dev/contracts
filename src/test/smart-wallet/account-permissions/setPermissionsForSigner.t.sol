// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import "../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { AccountPermissions } from "contracts/extension/upgradeable/AccountPermissions.sol";
import { AccountExtension } from "contracts/prebuilts/account/utils/AccountExtension.sol";

// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";

// Target
import { Account as SimpleAccount } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { DynamicAccountFactory, DynamicAccount } from "contracts/prebuilts/account/dynamic/DynamicAccountFactory.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
}

contract NFTRejector {
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        revert("NFTs not accepted");
    }
}

contract AccountPermissionsTest_setPermissionsForSigner is BaseTest {
    event AdminUpdated(address indexed signer, bool isAdmin);

    event SignerPermissionsUpdated(
        address indexed authorizingSigner,
        address indexed targetSigner,
        IAccountPermissions.SignerPermissionRequest permissions
    );

    // Target contracts
    EntryPoint private constant entrypoint = EntryPoint(payable(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789));
    DynamicAccountFactory private accountFactory;

    // Mocks
    Number internal numberContract;

    // Test params
    uint256 private accountAdminPKey = 100;
    address private accountAdmin;

    uint256 private accountSignerPKey = 200;
    address private accountSigner;

    uint256 private nonSignerPKey = 300;
    address private nonSigner;

    bytes internal data = bytes("");

    // UserOp terminology: `sender` is the smart wallet.
    address private sender = 0x78b942FBC9126b4Ed8384Bb9dd1420Ea865be91a;
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

    function _signSignerPermissionRequestInvalid(
        IAccountPermissions.SignerPermissionRequest memory _req
    ) internal view returns (bytes memory signature) {
        bytes32 typedDataHash = _prepareSignature(_req);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x111, typedDataHash);
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
            callGasLimit: 5_000_000,
            verificationGasLimit: 5_000_000,
            preVerificationGas: 5_000_000,
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
        address _deployedEntrypoint = address(new EntryPoint());
        vm.etch(address(entrypoint), bytes(_deployedEntrypoint.code));

        // Setting up default extension.
        IExtension.Extension memory defaultExtension;

        defaultExtension.metadata = IExtension.ExtensionMetadata({
            name: "AccountExtension",
            metadataURI: "ipfs://AccountExtension",
            implementation: address(new AccountExtension())
        });

        defaultExtension.functions = new IExtension.ExtensionFunction[](7);

        defaultExtension.functions[0] = IExtension.ExtensionFunction(
            AccountExtension.supportsInterface.selector,
            "supportsInterface(bytes4)"
        );
        defaultExtension.functions[1] = IExtension.ExtensionFunction(
            AccountExtension.execute.selector,
            "execute(address,uint256,bytes)"
        );
        defaultExtension.functions[2] = IExtension.ExtensionFunction(
            AccountExtension.executeBatch.selector,
            "executeBatch(address[],uint256[],bytes[])"
        );
        defaultExtension.functions[3] = IExtension.ExtensionFunction(
            ERC721Holder.onERC721Received.selector,
            "onERC721Received(address,address,uint256,bytes)"
        );
        defaultExtension.functions[4] = IExtension.ExtensionFunction(
            ERC1155Holder.onERC1155Received.selector,
            "onERC1155Received(address,address,uint256,uint256,bytes)"
        );
        defaultExtension.functions[5] = IExtension.ExtensionFunction(
            bytes4(0), // Selector for `receive()` function.
            "receive()"
        );
        defaultExtension.functions[6] = IExtension.ExtensionFunction(
            AccountExtension.isValidSignature.selector,
            "isValidSignature(bytes32,bytes)"
        );

        IExtension.Extension[] memory extensions = new IExtension.Extension[](1);
        extensions[0] = defaultExtension;

        // deploy account factory
        accountFactory = new DynamicAccountFactory(deployer, extensions);
        // deploy dummy contract
        numberContract = new Number();
    }

    function _setup_executeTransaction() internal {
        bytes memory initCallData = abi.encodeWithSignature("createAccount(address,bytes)", accountAdmin, data);
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

    function test_state_targetAdminNotAdmin() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        bool adminStatusBefore = SimpleAccount(payable(account)).isAdmin(accountSigner);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            1,
            approvedTargets,
            0,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig = _signSignerPermissionRequest(permissionsReq);
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);

        bool adminStatusAfter = SimpleAccount(payable(account)).isAdmin(accountSigner);

        assertEq(adminStatusBefore, false);
        assertEq(adminStatusAfter, true);
    }

    function test_state_targetAdminIsAdmin() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        {
            IAccountPermissions.SignerPermissionRequest memory request = IAccountPermissions.SignerPermissionRequest(
                accountSigner,
                1,
                approvedTargets,
                1,
                0,
                type(uint128).max,
                0,
                type(uint128).max,
                uidCache
            );

            bytes memory sig2 = _signSignerPermissionRequest(request);
            SimpleAccount(payable(account)).setPermissionsForSigner(request, sig2);

            address[] memory adminsBefore = SimpleAccount(payable(account)).getAllAdmins();
            assertEq(adminsBefore[1], accountSigner);
        }

        bool adminStatusBefore = SimpleAccount(payable(account)).isAdmin(accountAdmin);

        uidCache = bytes32("new uid");

        IAccountPermissions.SignerPermissionRequest memory req = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            2,
            approvedTargets,
            1,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        bytes memory sig3 = _signSignerPermissionRequest(req);
        SimpleAccount(payable(account)).setPermissionsForSigner(req, sig3);

        bool adminStatusAfter = SimpleAccount(payable(account)).isAdmin(accountSigner);
        address[] memory adminsAfter = SimpleAccount(payable(account)).getAllAdmins();

        assertEq(adminStatusBefore, true);
        assertEq(adminStatusAfter, false);
        assertEq(adminsAfter.length, 1);
    }

    function test_revert_attemptReplayUID() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            1,
            approvedTargets,
            1,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        bytes memory sig = _signSignerPermissionRequest(permissionsReq);
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);

        // Attempt replay UID

        IAccountPermissions.SignerPermissionRequest memory permissionsReqTwo = IAccountPermissions
            .SignerPermissionRequest(
                accountSigner,
                1,
                approvedTargets,
                0,
                0,
                type(uint128).max,
                0,
                type(uint128).max,
                uidCache
            );

        sig = _signSignerPermissionRequest(permissionsReqTwo);
        vm.expectRevert();
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReqTwo, sig);
    }

    function test_event_addAdmin_AdminUpdated() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            1,
            approvedTargets,
            1,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        bytes memory sig = _signSignerPermissionRequest(permissionsReq);

        vm.expectEmit(true, false, false, true);
        emit AdminUpdated(accountSigner, true);
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);
    }

    function test_event_removeAdmin_AdminUpdated() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            2,
            approvedTargets,
            1,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        bytes memory sig = _signSignerPermissionRequest(permissionsReq);

        vm.expectEmit(true, false, false, true);
        emit AdminUpdated(accountSigner, false);
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);
    }

    function test_revert_timeBeforeStart() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            1,
            approvedTargets,
            0,
            0,
            type(uint128).max,
            uint128(block.timestamp + 1000),
            type(uint128).max,
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig = _signSignerPermissionRequest(permissionsReq);
        vm.expectRevert("!period");
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);
    }

    function test_revert_timeAfterExpiry() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            1,
            approvedTargets,
            0,
            0,
            type(uint128).max,
            0,
            uint128(block.timestamp - 1),
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig = _signSignerPermissionRequest(permissionsReq);
        vm.expectRevert("!period");
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);
    }

    function test_revert_SignerNotAdmin() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            0,
            approvedTargets,
            0,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig = _signSignerPermissionRequestInvalid(permissionsReq);
        vm.expectRevert(bytes("!sig"));
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);
    }

    function test_revert_SignerAlreadyAdmin() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](0);

        {
            //set admin status
            IAccountPermissions.SignerPermissionRequest memory req = IAccountPermissions.SignerPermissionRequest(
                accountSigner,
                1,
                approvedTargets,
                0,
                0,
                type(uint128).max,
                0,
                type(uint128).max,
                uidCache
            );

            vm.prank(accountAdmin);
            bytes memory sig2 = _signSignerPermissionRequest(req);
            SimpleAccount(payable(account)).setPermissionsForSigner(req, sig2);
        }

        //test set signerPerms as admin

        uidCache = bytes32("new uid");

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            0,
            approvedTargets,
            0,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig3 = _signSignerPermissionRequest(permissionsReq);
        vm.expectRevert("admin");
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig3);
    }

    function test_state_setPermissionsForSigner() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](1);
        approvedTargets[0] = address(numberContract);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            0,
            approvedTargets,
            1,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig = _signSignerPermissionRequest(permissionsReq);
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);

        IAccountPermissions.SignerPermissions[] memory allSigners = SimpleAccount(payable(account)).getAllSigners();
        assertEq(allSigners[0].signer, accountSigner);
        assertEq(allSigners[0].approvedTargets[0], address(numberContract));
        assertEq(allSigners[0].nativeTokenLimitPerTransaction, 1);
        assertEq(allSigners[0].startTimestamp, 0);
        assertEq(allSigners[0].endTimestamp, type(uint128).max);
    }

    function test_event_addSigner() public {
        _setup_executeTransaction();

        address account = accountFactory.getAddress(accountAdmin, bytes(""));
        address[] memory approvedTargets = new address[](1);
        approvedTargets[0] = address(numberContract);

        IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
            accountSigner,
            0,
            approvedTargets,
            1,
            0,
            type(uint128).max,
            0,
            type(uint128).max,
            uidCache
        );

        vm.prank(accountAdmin);
        bytes memory sig = _signSignerPermissionRequest(permissionsReq);

        vm.expectEmit(true, true, false, true);
        emit SignerPermissionsUpdated(accountAdmin, accountSigner, permissionsReq);
        SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);
    }
}
