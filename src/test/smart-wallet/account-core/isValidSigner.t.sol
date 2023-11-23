// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import { BaseTest } from "../../utils/BaseTest.sol";
import "contracts/external-deps/openzeppelin/proxy/Clones.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { AccountPermissions, EnumerableSet, ECDSA } from "contracts/extension/upgradeable/AccountPermissions.sol";

// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";

// Target
import { DynamicAccountFactory, DynamicAccount, BaseAccountFactory } from "contracts/prebuilts/account/dynamic/DynamicAccountFactory.sol";

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

contract MyDynamicAccount is DynamicAccount {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(
        IEntryPoint _entrypoint,
        Extension[] memory _defaultExtensions
    ) DynamicAccount(_entrypoint, _defaultExtensions) {}

    function setPermissionsForSigner(
        address _signer,
        uint256 _nativeTokenLimit,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) public {
        _accountPermissionsStorage().signerPermissions[_signer] = SignerPermissionsStatic(
            _nativeTokenLimit,
            uint128(_startTimestamp),
            uint128(_endTimestamp)
        );
    }

    function setApprovedTargetsForSigner(address _signer, address[] memory _approvedTargets) public {
        uint256 len = _approvedTargets.length;
        for (uint256 i = 0; i < len; i += 1) {
            _accountPermissionsStorage().approvedTargets[_signer].add(_approvedTargets[i]);
        }
    }

    function _setAdmin(address _account, bool _isAdmin) internal virtual override {
        _accountPermissionsStorage().isAdmin[_account] = _isAdmin;
    }

    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {}
}

contract AccountCoreTest_isValidSigner is BaseTest {
    // Target contracts
    EntryPoint private entrypoint;
    DynamicAccountFactory private accountFactory;
    MyDynamicAccount private account;

    // Mocks
    Number internal numberContract;

    // Test params
    uint256 private accountAdminPKey = 100;
    address private accountAdmin;

    uint256 private accountSignerPKey = 200;
    address private accountSigner;

    uint256 private nonSignerPKey = 300;
    address private nonSigner;

    address private opSigner;
    uint256 private startTimestamp;
    uint256 private endTimestamp;
    uint256 private nativeTokenLimit;
    UserOperation private op;

    bytes internal data = bytes("");

    function _setupUserOp(
        uint256 _signerPKey,
        bytes memory _initCode,
        bytes memory _callDataForEntrypoint
    ) internal returns (UserOperation memory) {
        uint256 nonce = entrypoint.getNonce(address(account), 0);

        // Get user op fields
        UserOperation memory op = UserOperation({
            sender: address(account),
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

        return op;
    }

    function _setupUserOpExecute(
        uint256 _signerPKey,
        bytes memory _initCode,
        address _target,
        uint256 _value,
        bytes memory _callData
    ) internal returns (UserOperation memory) {
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
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _callData
    ) internal returns (UserOperation memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "executeBatch(address[],uint256[],bytes[])",
            _targets,
            _values,
            _callData
        );

        return _setupUserOp(_signerPKey, _initCode, callDataForEntrypoint);
    }

    function _setupUserOpInvalidFunction(
        uint256 _signerPKey,
        bytes memory _initCode
    ) internal returns (UserOperation memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature("invalidFunction()");

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

        IExtension.Extension[] memory extensions;

        // deploy account factory
        accountFactory = new DynamicAccountFactory(deployer, extensions);
        // deploy dummy contract
        numberContract = new Number();

        address accountImpl = address(new MyDynamicAccount(IEntryPoint(payable(address(entrypoint))), extensions));
        address _account = Clones.cloneDeterministic(accountImpl, "salt");
        account = MyDynamicAccount(payable(_account));
        account.initialize(accountAdmin, "");
    }

    function test_isValidSigner_whenSignerIsAdmin() public {
        opSigner = accountAdmin;
        UserOperation memory _op; // empty op since it's not relevant for this check
        bool isValid = DynamicAccount(payable(account)).isValidSigner(opSigner, _op);

        assertTrue(isValid);
    }

    modifier whenNotAdmin() {
        opSigner = accountSigner;
        _;
    }

    function test_isValidSigner_invalidTimestamps() public whenNotAdmin {
        UserOperation memory _op; // empty op since it's not relevant for this check
        startTimestamp = 100;
        endTimestamp = 200;
        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        vm.warp(201); // block timestamp greater than end timestamp
        bool isValid = account.isValidSigner(opSigner, _op);

        assertFalse(isValid);

        vm.warp(200); // block timestamp equal to end timestamp
        isValid = account.isValidSigner(opSigner, _op);

        assertFalse(isValid);

        vm.warp(99); // block timestamp less than start timestamp
        isValid = account.isValidSigner(opSigner, _op);

        assertFalse(isValid);
    }

    modifier whenValidTimestamps() {
        startTimestamp = 100;
        endTimestamp = 200;
        vm.warp(150); // block timestamp within start and end timestamps
        _;
    }

    function test_isValidSigner_noApprovedTargets() public whenNotAdmin whenValidTimestamps {
        UserOperation memory _op; // empty op since it's not relevant for this check
        address[] memory _approvedTargets;
        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        bool isValid = account.isValidSigner(opSigner, _op);

        assertFalse(isValid);
    }

    // ==================
    // ======= Test branch: wildcard
    // ==================

    function test_isValidSigner_wildcardExecute_breachNativeTokenLimit() public whenNotAdmin whenValidTimestamps {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(0);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        op = _setupUserOpExecute(accountSignerPKey, bytes(""), address(0x123), 10, bytes(""));

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }

    function test_isValidSigner_wildcardExecuteBatch_breachNativeTokenLimit() public whenNotAdmin whenValidTimestamps {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(0);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        for (uint256 i = 0; i < count; i += 1) {
            targets[i] = address(numberContract);
            values[i] = 10;
            callData[i] = abi.encodeWithSignature("incrementNum()", i);
        }

        op = _setupUserOpExecuteBatch(accountSignerPKey, bytes(""), targets, values, callData);

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }

    modifier whenWithinNativeTokenLimit() {
        nativeTokenLimit = 1000;
        _;
    }

    function test_isValidSigner_wildcardExecute() public whenNotAdmin whenValidTimestamps whenWithinNativeTokenLimit {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(0);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        op = _setupUserOpExecute(accountSignerPKey, bytes(""), address(0x123), 10, bytes(""));

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertTrue(isValid);
    }

    function test_isValidSigner_wildcardExecuteBatch()
        public
        whenNotAdmin
        whenValidTimestamps
        whenWithinNativeTokenLimit
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(0);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        for (uint256 i = 0; i < count; i += 1) {
            targets[i] = address(numberContract);
            values[i] = 10;
            callData[i] = abi.encodeWithSignature("incrementNum()", i);
        }

        op = _setupUserOpExecuteBatch(accountSignerPKey, bytes(""), targets, values, callData);

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertTrue(isValid);
    }

    function test_isValidSigner_wildcardInvalidFunction()
        public
        whenNotAdmin
        whenValidTimestamps
        whenWithinNativeTokenLimit
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(0);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        op = _setupUserOpInvalidFunction(accountSignerPKey, bytes(""));

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }

    // ==================
    // ======= Test branch: not wildcard
    // ==================

    function test_isValidSigner_execute_callingWrongTarget()
        public
        whenNotAdmin
        whenValidTimestamps
        whenWithinNativeTokenLimit
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(numberContract);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        address wrongTarget = address(0x123);
        op = _setupUserOpExecute(accountSignerPKey, bytes(""), wrongTarget, 10, bytes(""));

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }

    function test_isValidSigner_executeBatch_callingWrongTarget()
        public
        whenNotAdmin
        whenValidTimestamps
        whenWithinNativeTokenLimit
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(numberContract);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);
        address wrongTarget = address(0x123);
        for (uint256 i = 0; i < count; i += 1) {
            targets[i] = wrongTarget;
            values[i] = 10;
            callData[i] = abi.encodeWithSignature("incrementNum()", i);
        }

        op = _setupUserOpExecuteBatch(accountSignerPKey, bytes(""), targets, values, callData);

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }

    modifier whenCorrectTarget() {
        _;
    }

    function test_isValidSigner_execute_breachNativeTokenLimit()
        public
        whenNotAdmin
        whenValidTimestamps
        whenCorrectTarget
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(numberContract);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        op = _setupUserOpExecute(accountSignerPKey, bytes(""), address(numberContract), 10, bytes(""));

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }

    function test_isValidSigner_executeBatch_breachNativeTokenLimit()
        public
        whenNotAdmin
        whenValidTimestamps
        whenCorrectTarget
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(numberContract);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        for (uint256 i = 0; i < count; i += 1) {
            targets[i] = address(numberContract);
            values[i] = 10;
            callData[i] = abi.encodeWithSignature("incrementNum()", i);
        }

        op = _setupUserOpExecuteBatch(accountSignerPKey, bytes(""), targets, values, callData);

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }

    function test_isValidSigner_execute()
        public
        whenNotAdmin
        whenValidTimestamps
        whenWithinNativeTokenLimit
        whenCorrectTarget
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(numberContract);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        op = _setupUserOpExecute(accountSignerPKey, bytes(""), address(numberContract), 10, bytes(""));

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertTrue(isValid);
    }

    function test_isValidSigner_executeBatch()
        public
        whenNotAdmin
        whenValidTimestamps
        whenWithinNativeTokenLimit
        whenCorrectTarget
    {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(numberContract);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        for (uint256 i = 0; i < count; i += 1) {
            targets[i] = address(numberContract);
            values[i] = 10;
            callData[i] = abi.encodeWithSignature("incrementNum()", i);
        }

        op = _setupUserOpExecuteBatch(accountSignerPKey, bytes(""), targets, values, callData);

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertTrue(isValid);
    }

    function test_isValidSigner_invalidFunction() public whenNotAdmin whenValidTimestamps whenWithinNativeTokenLimit {
        // set wildcard
        address[] memory _approvedTargets = new address[](1);
        _approvedTargets[0] = address(numberContract);
        account.setApprovedTargetsForSigner(opSigner, _approvedTargets);

        // user op execute
        op = _setupUserOpInvalidFunction(accountSignerPKey, bytes(""));

        account.setPermissionsForSigner(opSigner, nativeTokenLimit, startTimestamp, endTimestamp);

        bool isValid = account.isValidSigner(opSigner, op);

        assertFalse(isValid);
    }
}
