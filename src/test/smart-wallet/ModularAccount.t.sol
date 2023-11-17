// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import "../utils/BaseTest.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";

// Target
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { ModularAccountFactory } from "contracts/prebuilts/account/modular/ModularAccountFactory.sol";
import { ModularAccount } from "contracts/prebuilts/account/modular/ModularAccount.sol";
import { SingleOwnerValidator } from "contracts/prebuilts/account/modular/plugins/validation/SingleOwnerValidator.sol";

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

contract ModularAccountTest is BaseTest {
    // Target contracts
    EntryPoint private entrypoint;
    ModularAccountFactory private accountFactory;
    SingleOwnerValidator private validator;

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
    address private sender = 0xd9E938fa9B0D65de58bdC1B88832b3E46c300795;
    address payable private beneficiary = payable(address(0x45654));

    bytes32 private uidCache = bytes32("random uid");

    address internal factoryImpl;

    event AccountCreated(address indexed account, address indexed accountAdmin);

    function _prepareSignature(IAccountPermissions.SignerPermissionRequest memory _req)
        internal
        view
        returns (bytes32 typedDataHash)
    {
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

    function _signSignerPermissionRequest(IAccountPermissions.SignerPermissionRequest memory _req)
        internal
        view
        returns (bytes memory signature)
    {
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

    function _setupUserOpWithSender(
        bytes memory _initCode,
        bytes memory _callDataForEntrypoint,
        address _sender
    ) internal returns (UserOperation[] memory ops) {
        uint256 nonce = entrypoint.getNonce(_sender, 0);

        // Get user op fields
        UserOperation memory op = UserOperation({
            sender: _sender,
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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(accountAdminPKey, msgHash);
        bytes memory userOpSignature = abi.encodePacked(r, s, v);

        address recoveredSigner = ECDSA.recover(msgHash, v, r, s);
        address expectedSigner = vm.addr(accountAdminPKey);
        assertEq(recoveredSigner, expectedSigner);

        op.signature = userOpSignature;

        // Store UserOp
        ops = new UserOperation[](1);
        ops[0] = op;
    }

    function _setupUserOpExecuteWithSender(
        bytes memory _initCode,
        address _target,
        uint256 _value,
        bytes memory _callData,
        address _sender
    ) internal returns (UserOperation[] memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            _target,
            _value,
            _callData
        );

        return _setupUserOpWithSender(_initCode, callDataForEntrypoint, _sender);
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

    /// @dev Returns the salt used when deploying an Account.
    function _generateSalt(address _admin, bytes memory _data) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_admin, _data));
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

        validator = new SingleOwnerValidator();
        // deploy account factory
        factoryImpl = address(new ModularAccountFactory(payable(address(entrypoint))));
        accountFactory = ModularAccountFactory(
            address(
                payable(
                    new TWProxy(
                        factoryImpl,
                        abi.encodeWithSignature("initialize(address,string)", deployer, "https://example.com")
                    )
                )
            )
        );
        // deploy dummy contract
        numberContract = new Number();
    }

    /*///////////////////////////////////////////////////////////////
                        Test: initial state
    //////////////////////////////////////////////////////////////*/

    function test_initialState() external {
        assertEq(accountFactory.entrypoint(), address(entrypoint));
        assertEq(accountFactory.contractURI(), "https://example.com");
        assertEq(accountFactory.hasRole(0x00, deployer), true);
    }

    function test_revert_initializeImplementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        ModularAccountFactory(factoryImpl).initialize(deployer, "https://example.com");
    }

    /*///////////////////////////////////////////////////////////////
                        Test: creating an account
    //////////////////////////////////////////////////////////////*/

    /// @dev Create an account by directly calling the factory.
    function test_state_createAccount_viaFactory() public {
        bytes memory initData = abi.encode(accountAdmin, address(validator));

        vm.expectEmit(true, true, false, true);
        emit AccountCreated(sender, accountAdmin);
        accountFactory.createAccount(accountAdmin, initData);

        address[] memory allAccounts = accountFactory.getAllAccounts();
        assertEq(allAccounts.length, 1);
        assertEq(allAccounts[0], sender);

        address[] memory signers = accountFactory.getAccountsOfSigner(accountAdmin);
        assertEq(signers.length, 1);
        assertEq(signers[0], sender);
    }

    /// @dev Create an account via Entrypoint.
    function test_state_createAccount_viaEntrypointSingle() public {
        bytes memory initData = abi.encode(accountAdmin, address(validator));

        bytes memory initCallData = abi.encodeWithSignature("createAccount(address,bytes)", accountAdmin, initData);
        bytes memory initCode = abi.encodePacked(abi.encodePacked(address(accountFactory)), initCallData);

        UserOperation[] memory userOpCreateAccount = _setupUserOpExecute(
            accountAdminPKey,
            initCode,
            address(0),
            0,
            bytes("")
        );

        vm.expectEmit(true, true, false, true);
        emit AccountCreated(sender, accountAdmin);
        EntryPoint(entrypoint).handleOps(userOpCreateAccount, beneficiary);

        address[] memory allAccounts = accountFactory.getAllAccounts();
        assertEq(allAccounts.length, 1);
        assertEq(allAccounts[0], sender);
    }

    /// @dev Try registering with factory with a contract not deployed by factory.
    function test_revert_onRegister_nonFactoryChildContract() public {
        vm.prank(address(0x12345));
        vm.expectRevert("AccountFactory: not an account.");
        accountFactory.onRegister(_generateSalt(accountAdmin, ""));
    }

    //     /*///////////////////////////////////////////////////////////////
    //                     Test: performing a contract call
    //     //////////////////////////////////////////////////////////////*/

    function _setup_executeTransaction() internal {
        bytes memory initData = abi.encode(accountAdmin, address(validator));
        bytes memory initCallData = abi.encodeWithSignature("createAccount(address,bytes)", accountAdmin, initData);
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

    /// @dev Perform a state changing transaction directly via account.
    function test_state_executeTransaction() public {
        _setup_executeTransaction();

        bytes memory initData = abi.encode(accountAdmin, address(validator));
        address account = accountFactory.getAddress(accountAdmin, initData);

        assertEq(numberContract.num(), 0);

        vm.prank(accountAdmin);
        ModularAccount(payable(account)).execute(
            address(numberContract),
            0,
            abi.encodeWithSignature("setNum(uint256)", 42)
        );

        assertEq(numberContract.num(), 42);
    }

    /// @dev Perform many state changing transactions in a batch directly via account.
    function test_state_executeBatchTransaction() public {
        _setup_executeTransaction();

        bytes memory initData = abi.encode(accountAdmin, address(validator));
        address account = accountFactory.getAddress(accountAdmin, initData);

        assertEq(numberContract.num(), 0);

        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        for (uint256 i = 0; i < count; i += 1) {
            targets[i] = address(numberContract);
            values[i] = 0;
            callData[i] = abi.encodeWithSignature("incrementNum()", i);
        }

        vm.prank(accountAdmin);
        ModularAccount(payable(account)).executeBatch(targets, values, callData);

        assertEq(numberContract.num(), count);
    }

    /// @dev Perform a state changing transaction via Entrypoint.
    function test_state_executeTransaction_viaEntrypoint() public {
        _setup_executeTransaction();

        assertEq(numberContract.num(), 0);

        UserOperation[] memory userOp = _setupUserOpExecute(
            accountAdminPKey,
            bytes(""),
            address(numberContract),
            0,
            abi.encodeWithSignature("setNum(uint256)", 42)
        );

        EntryPoint(entrypoint).handleOps(userOp, beneficiary);

        assertEq(numberContract.num(), 42);
    }

    /// @dev Perform many state changing transactions in a batch via Entrypoint.
    function test_state_executeBatchTransaction_viaEntrypoint() public {
        _setup_executeTransaction();

        assertEq(numberContract.num(), 0);

        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        for (uint256 i = 0; i < count; i += 1) {
            targets[i] = address(numberContract);
            values[i] = 0;
            callData[i] = abi.encodeWithSignature("incrementNum()", i);
        }

        UserOperation[] memory userOp = _setupUserOpExecuteBatch(
            accountAdminPKey,
            bytes(""),
            targets,
            values,
            callData
        );

        EntryPoint(entrypoint).handleOps(userOp, beneficiary);

        assertEq(numberContract.num(), count);
    }
}
