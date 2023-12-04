// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";

// Target
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Account as SimpleAccount } from "contracts/prebuilts/account/non-upgradeable/Account.sol";

import { IERC20 } from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

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

contract CrossChainTokenTransferMaster {
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
    address private sender = 0xBB956D56140CA3f3060986586A2631922a4B347E;
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

    /*///////////////////////////////////////////////////////////////
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

    /// @dev Perform many state changing transactions in a batch via Entrypoint.
    function _initiateTokenTransferWithLink(
        address _smartWalletAccount,
        address _ccip,
        address _link,
        address _token,
        uint64 _destinationChainSelector,
        address _receiver,
        uint _tokenAmount,
        uint _linkAmount
    ) public {
        _setup_executeTransaction();

        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        targets[0] = _link;
        values[0] = 0;
        callData[0] = abi.encodeWithSignature("approve(address, uint)", _ccip, _linkAmount);

        targets[1] = _token;
        values[1] = 0;
        callData[1] = abi.encodeWithSignature("approve(address, uint)", _ccip, _tokenAmount);

        targets[2] = _ccip;
        values[2] = 0;
        callData[2] = abi.encodeWithSignature(
            "transferTokensPayLINK(uint64 , address , address , address ,uint256 , uint256,   uint256 )",
            _destinationChainSelector,
            _receiver,
            _smartWalletAccount,
            _token,
            _tokenAmount,
            _linkAmount,
            _tokenAmount
        );

        UserOperation[] memory userOp = _setupUserOpExecuteBatch(
            accountAdminPKey,
            bytes(""),
            targets,
            values,
            callData
        );

        EntryPoint(entrypoint).handleOps(userOp, beneficiary);
    }

    function _initiateTokenTransferWithNativeToken(
        address _smartWalletAccount,
        address _ccip,
        address _token,
        uint64 _destinationChainSelector,
        address _receiver,
        uint _tokenAmount,
        uint _estimatedAmount
    ) public {
        _setup_executeTransaction();

        uint256 count = 2;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        targets[0] = _token;
        values[0] = 0;
        callData[0] = abi.encodeWithSignature("approve(address, uint)", _ccip, _tokenAmount);

        targets[1] = _ccip;
        values[1] = _estimatedAmount;
        callData[1] = abi.encodeWithSignature(
            "transferTokensPayNative( uint64 ,  address ,  address , address,  uint256 , uint256   )",
            _destinationChainSelector,
            _receiver,
            _smartWalletAccount,
            _token,
            _tokenAmount,
            _tokenAmount
        );
        UserOperation[] memory userOp = _setupUserOpExecuteBatch(
            accountAdminPKey,
            bytes(""),
            targets,
            values,
            callData
        );

        EntryPoint(entrypoint).handleOps(userOp, beneficiary);
    }

    /*///////////////////////////////////////////////////////////////
                Test: setting contract metadata
    //////////////////////////////////////////////////////////////*/

    // /// @dev Set contract metadata via admin or entrypoint.
    // function test_state_contractMetadata() public {
    //     _setup_executeTransaction();
    //     address account = accountFactory.getAddress(accountAdmin, bytes(""));

    //     vm.prank(accountAdmin);
    //     SimpleAccount(payable(account)).setContractURI("https://example.com");
    //     assertEq(SimpleAccount(payable(account)).contractURI(), "https://example.com");

    //     UserOperation[] memory userOp = _setupUserOpExecute(
    //         accountAdminPKey,
    //         bytes(""),
    //         address(account),
    //         0,
    //         abi.encodeWithSignature("setContractURI(string)", "https://thirdweb.com")
    //     );

    //     EntryPoint(entrypoint).handleOps(userOp, beneficiary);
    //     assertEq(SimpleAccount(payable(account)).contractURI(), "https://thirdweb.com");

    //     address[] memory approvedTargets = new address[](0);

    //     IAccountPermissions.SignerPermissionRequest memory permissionsReq = IAccountPermissions.SignerPermissionRequest(
    //         accountSigner,
    //         0,
    //         approvedTargets,
    //         1 ether,
    //         0,
    //         type(uint128).max,
    //         0,
    //         type(uint128).max,
    //         uidCache
    //     );

    //     vm.prank(accountAdmin);
    //     bytes memory sig = _signSignerPermissionRequest(permissionsReq);
    //     SimpleAccount(payable(account)).setPermissionsForSigner(permissionsReq, sig);

    //     UserOperation[] memory userOpViaSigner = _setupUserOpExecute(
    //         accountSignerPKey,
    //         bytes(""),
    //         address(account),
    //         0,
    //         abi.encodeWithSignature("setContractURI(string)", "https://thirdweb.com")
    //     );

    //     vm.expectRevert();
    //     EntryPoint(entrypoint).handleOps(userOpViaSigner, beneficiary);
    // }
}
