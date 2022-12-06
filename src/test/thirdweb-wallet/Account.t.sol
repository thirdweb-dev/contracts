// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Account, IAccount } from "contracts/thirdweb-wallet/Account.sol";
import { AccountAdmin, IAccountAdmin } from "contracts/thirdweb-wallet/AccountAdmin.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

import { BaseTest, ERC20, ERC721, ERC1155 } from "../utils/BaseTest.sol";

/**
 *  Basic actions [ACCOUNT]:
 *      - Deploy smart contracts
 *      - Make transactions on contracts
 *      - Sign messages
 *      - Own assets
 *
 *  Basic actions [ACCOUNT_ADMIN]:
 *      - Create accounts.
 *      - Change signer of account.
 *      - Relay transaction to contract wallet.
 *
 *
 *  ARCHITECTURE: https://whimsical.com/smart-contract-wallet-71eMdPs2y2GnG21Aaq8qXS
 */

// TODO: All signature verification must account for both contract and EOA signers.

contract DummyContract {
    uint256 public val;
    address public deployer;

    constructor() payable {
        val = msg.value;
        deployer = msg.sender;
    }

    receive() external payable {
        val += msg.value;
    }

    function revert() external {
        revert("Execution reverted.");
    }

    function withdraw() external {
        require(msg.sender == deployer);
        (msg.sender).call{ value: val }("");

        val = 0;
    }
}

contract AccountUtil is BaseTest {
    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256(
            "TransactionParams(address target,bytes data,uint256 nonce,uint256 value,uint256 gas,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    bytes32 private constant DEPLOY_TYPEHASH =
        keccak256(
            "DeployParams(bytes bytecode,bytes32 salt,uint256 value,uint256 nonce,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 internal nameHashWallet = keccak256(bytes("thirdwebWallet"));
    bytes32 internal versionHashWallet = keccak256(bytes("1"));
    bytes32 internal typehashEip712Wallet =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function signExecute(
        Account.TransactionParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                EXECUTE_TYPEHASH,
                _params.target,
                keccak256(bytes(_params.data)),
                _params.nonce,
                _params.value,
                _params.gas,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712Wallet, nameHashWallet, versionHashWallet, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function signDeploy(
        Account.DeployParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                DEPLOY_TYPEHASH,
                keccak256(bytes(_params.bytecode)),
                _params.salt,
                _params.value,
                _params.nonce,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712Wallet, nameHashWallet, versionHashWallet, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }
}

contract AccountAdminUtil is BaseTest {
    bytes32 private constant CREATE_TYPEHASH =
        keccak256(
            "CreateAccountParams(address signer,bytes32 credentials,bytes32 deploymentSalt,uint256 initialAccountBalance,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant SIGNER_UPDATE_TYPEHASH =
        keccak256(
            "SignerUpdateParams(address account,address newSigner,address currentSigner,bytes32 newCredentials,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant TRANSACTION_TYPEHASH =
        keccak256(
            "TransactionRequest(address signer,bytes32 credentials,uint256 value,uint256 gas,bytes data,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    bytes32 internal nameHash = keccak256(bytes("thirdwebWallet_Admin"));
    bytes32 internal versionHash = keccak256(bytes("1"));
    bytes32 internal typehashEip712 =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function signCreateAccount(
        IAccountAdmin.CreateAccountParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                CREATE_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.deploymentSalt,
                _params.initialAccountBalance,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function signSignerUpdate(
        AccountAdmin.SignerUpdateParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                SIGNER_UPDATE_TYPEHASH,
                _params.account,
                _params.newSigner,
                _params.currentSigner,
                _params.newCredentials,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function signTransactionRequest(
        AccountAdmin.TransactionRequest memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.value,
                _params.gas,
                keccak256(_params.data),
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }
}

contract AccountAdminData {
    /// @notice Emitted when an account is created.
    event AccountCreated(address indexed account, address indexed signerOfAccount, address indexed creator);

    /// @notice Emitted when the signer for an account is updated.
    event SignerUpdated(address indexed account, address indexed newSigner);

    /// @notice Emitted on a call to an account.
    event CallResult(bool success, bytes result);
}

contract ThirdwebWalletTest is AccountUtil, AccountAdminUtil, AccountAdminData {
    AccountAdmin private admin;
    Account private wallet;

    uint256 public privateKey1 = 1234;
    uint256 public privateKey2 = 6789;

    address private signer1;
    address private signer2;

    function setUp() public override {
        super.setUp();

        // Deploy Architecture:Admin i.e. the entrypoint for a client.
        admin = new AccountAdmin(new address[](0));

        signer1 = vm.addr(privateKey1);
        signer2 = vm.addr(privateKey2);
    }

    /**
     *    REQUIREMENTS FOR TXS TO ACCOUNT_ADMIN.
     *
     *  - Signature from Architecture:BurnerWallet (BW).
     *  - Payload signed by (BW) must contain a validity start and end timestamp.
     *  - Payload signed by (BW) must contain all argument values passed to the function other than the signature.
     */

    /**
     *    REQUIREMENTS FOR TXS FROM ACCOUNT_ADMIN -> ACCOUNT.
     *
     *  - Signature from Architecture:BurnerWallet (BW).
     *  - Signing (BW) must an approved signer of ACCOUNT.
     *  - Payload signed by (BW) must contain a validity start and end timestamp.
     *  - Payload signed by (BW) must contain all argument values passed to the function other than the signature.
     */

    /**
     *    INVARIABLES FOR ACCOUNT_ADMIN
     *
     *  - One and the same account associated with a signer, credentials and a (signer, credentials) pair.
     */

    /**
     *    INVARIABLES FOR ACCOUNT
     *
     *  - One and only one ACCOUNT_ADMIN approved to call into ACCOUNT.
     *  - One and only one signer approved to control ACCOUNT.
     */

    /*///////////////////////////////////////////////////////////////
                Test action: Creating an account.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Creates an account for a (signer, credentials) pair.
     *
     *  Info passed by client:
     *      - signer address
     *      - credentials
     *      - signature of intent from signer
     *      - validity start and end timestamps
     */
    function test_state_createAccount() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);
        assertEq(Account(payable(account)).nonce(), 0);
        assertEq(Account(payable(account)).controller(), address(admin));
    }

    /// @dev Creates an account for a (signer, credentials) pair with a pre-determined address.
    function test_state_createAccount_deterministicAddress() external {
        bytes32 salt = keccak256("1");
        bytes memory bytecode = abi.encodePacked(type(Account).creationCode, abi.encode(address(admin), signer1));
        bytes32 bytecodeHash = keccak256(bytecode);

        address predictedAddress = Create2.computeAddress(salt, bytecodeHash, address(admin));

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(account, predictedAddress);
    }

    /// @dev Creates an account for a (signer, credentials) pair with an initial native token balance.
    function test_balances_createAccount_withInitialBalance() external {
        uint256 initialBalance = 1 ether;
        vm.deal(signer1, initialBalance);

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: initialBalance,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount{ value: initialBalance }(params, signature);

        assertEq(account.balance, initialBalance);
    }

    /// @dev On creation of an account, event `AccountCreated` is emitted with: account, signer-of-account and creator (i.e. caller) address.
    function test_events_createAccount_AccountCreated() external {
        bytes32 salt = keccak256("1");
        bytes memory bytecode = abi.encodePacked(type(Account).creationCode, abi.encode(address(admin), signer1));
        bytes32 bytecodeHash = keccak256(bytecode);

        address predictedAddress = Create2.computeAddress(salt, bytecodeHash, address(admin));

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.expectEmit(true, true, true, true);
        emit AccountCreated(predictedAddress, signer1, signer2);
        vm.prank(signer2);
        admin.createAccount(params, signature);
    }

    /// @dev Cannot create an account with empty credentials (bytes32(0)).
    function test_revert_createAccount_emptyCredentials() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: bytes32(0), // empty credentials
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.expectRevert("AccountAdmin: invalid credentials.");
        admin.createAccount(params, signature);
    }

    /// @dev Must sent the exact native token value with transaction as the account's intended initial balance on creation.
    function test_revert_createAccount_incorrectValueSentForInitialBalance() external {
        uint256 initialBalance = 1 ether;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: initialBalance,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.expectRevert("AccountAdmin: incorrect value sent.");
        admin.createAccount{ value: initialBalance - 1 }(params, signature); // Incorrect value sent.
    }

    /// @dev Must not repeat deployment salt.
    function test_revert_createAccount_repeatingDeploymentSalt() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        admin.createAccount(params, signature);

        IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
            signer: signer2,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signCreateAccount(params2, privateKey2, address(admin));
        vm.expectRevert();
        admin.createAccount(params2, signature2);
    }

    /// @dev Signature of intent must be from the target signer for whom the account is created.
    function test_revert_createAccount_signatureNotFromTargetSigner() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer2, // Signer2 is intended signer for account.
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin)); // Signature from Signer1 not Signer2

        vm.expectRevert("AccountAdmin: invalid signer.");
        admin.createAccount(params, signature);
    }

    /// @dev The signer must not already have an associated account.
    function test_revert_createAccount_signerAlreadyHasAccount() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        admin.createAccount(params, signature);

        IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
            signer: signer1, // Same signer
            credentials: keccak256("2"),
            deploymentSalt: keccak256("2"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signCreateAccount(params2, privateKey1, address(admin));
        vm.expectRevert("AccountAdmin: signer already has account.");
        admin.createAccount(params2, signature2);
    }

    /// @dev The signer must not already have an associated account.
    function test_revert_createAccount_credentialsAlreadyUsed() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        admin.createAccount(params, signature);

        IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"), // Already used credentials
            deploymentSalt: keccak256("2"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signCreateAccount(params2, privateKey1, address(admin));
        vm.expectRevert("AccountAdmin: credentials already used.");
        admin.createAccount(params2, signature2);
    }

    /// @dev The request to create account must not be processed at/after validity end timestamp.
    function test_revert_createAccount_requestedAfterValidityEnd() external {
        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.warp(validityEnd);
        vm.expectRevert("AccountAdmin: request premature or expired.");
        admin.createAccount(params, signature);
    }

    /// @dev The request to create account must not be processed before validity start timestamp.
    function test_revert_createAccount_requestedBeforeValidityStart() external {
        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.warp(validityStart - 1);
        vm.expectRevert("AccountAdmin: request premature or expired.");
        admin.createAccount(params, signature);
    }

    /*///////////////////////////////////////////////////////////////
                Test action: Changing signer for an account.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Changes the signer approved to control WALLET. WALLET_ENTRYPOINT tracks this change.
     *
     *  Info passed by client:
     *      - account address
     *      - incumbent signer for account
     *      - new signer for account
     *      - new credentials for account
     *      - signature of intent by incumbent signer.
     *      - validity start and end timestamps
     */
    function test_state_changeSignerForAccount() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);

        assertEq(Account(payable(account)).signer(), signer2);
    }

    function test_revert_changeSignerForAccount_newSignerAlreadyHasAccount() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer1,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("AccountAdmin: signer already has account.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_signatureNotFromIncumbentSigner() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey2, address(admin));

        vm.expectRevert("AccountAdmin: invalid signer.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_changingForIncorrectAccount() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: address(0x123),
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("AccountAdmin: incorrect account provided.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_emptyCredentials() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: bytes32(0),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("AccountAdmin: invalid credentials.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_credentialsAlreadyUsed() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("1"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("AccountAdmin: credentials already used.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_requestBeforeValidityStart() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.warp(validityStart - 1);
        vm.expectRevert("AccountAdmin: request premature or expired.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_requestAfterValidityEnd() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Account(payable(account)).signer(), signer1);

        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IAccountAdmin.SignerUpdateParams memory signerUpdateParams = IAccountAdmin.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.warp(validityEnd);
        vm.expectRevert("AccountAdmin: request premature or expired.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    /*///////////////////////////////////////////////////////////////
                Test action: Deploying a smart contract.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev WALLET (account) deploys a smart contract.
     *
     *  Info passed by client:
     *      - create2 parameters: initial balance, salt, contract bytecode.
     *      - wallet nonce
     *      - signature of intent from sigenr
     *      - validity start and end timestamps
     */
    function test_state_deploy() external {
        // Create account.
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Deploy contract with account.
        Account.DeployParams memory deployParams = IAccount.DeployParams({
            bytecode: type(DummyContract).creationCode,
            salt: keccak256("deploy"),
            value: 0,
            nonce: account.nonce(),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

        bytes memory transactionData = abi.encodeWithSelector(
            Account.deploy.selector,
            deployParams,
            signatureForDeploy
        );

        IAccountAdmin.TransactionRequest memory txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 1_000_000,
            data: transactionData,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));
        (bool success, ) = admin.execute(txRequest, signatureForTx);

        assertEq(success, true);

        address predictedAddress = Create2.computeAddress(
            deployParams.salt,
            keccak256(abi.encodePacked(deployParams.bytecode)),
            accountAddress
        );

        assertEq(DummyContract(payable(predictedAddress)).deployer(), accountAddress);
    }

    function test_balances_deploy_withInitialBalance() external {
        // Create account.
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Deploy contract with account.
        Account.DeployParams memory deployParams = IAccount.DeployParams({
            bytecode: type(DummyContract).creationCode,
            salt: keccak256("deploy"),
            value: 1 ether,
            nonce: account.nonce(),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

        bytes memory transactionData = abi.encodeWithSelector(
            Account.deploy.selector,
            deployParams,
            signatureForDeploy
        );

        IAccountAdmin.TransactionRequest memory txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 1 ether,
            gas: 1_000_000,
            data: transactionData,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));
        (bool success, ) = admin.execute{ value: txRequest.value }(txRequest, signatureForTx);

        assertEq(success, true);

        address predictedAddress = Create2.computeAddress(
            deployParams.salt,
            keccak256(abi.encodePacked(deployParams.bytecode)),
            accountAddress
        );

        assertEq(DummyContract(payable(predictedAddress)).deployer(), accountAddress);
        assertEq(predictedAddress.balance, txRequest.value);
    }

    function test_revert_deploy_incorrectValueSentForInitialBalance() external {
        // Create account.
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Deploy contract with account.
        Account.DeployParams memory deployParams = IAccount.DeployParams({
            bytecode: type(DummyContract).creationCode,
            salt: keccak256("deploy"),
            value: 0,
            nonce: account.nonce(),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

        bytes memory transactionData = abi.encodeWithSelector(
            Account.deploy.selector,
            deployParams,
            signatureForDeploy
        );

        IAccountAdmin.TransactionRequest memory txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 1 ether,
            gas: 1_000_000,
            data: transactionData,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));
        vm.expectRevert("AccountAdmin: incorrect value sent.");
        admin.execute{ value: txRequest.value - 1 }(txRequest, signatureForTx);
    }

    function test_revert_deploy_repeatingDeploymentSaltForSameContract() external {
        // Create account.
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Deploy contract with account.
        Account.DeployParams memory deployParams = IAccount.DeployParams({
            bytecode: type(DummyContract).creationCode,
            salt: keccak256("deploy"),
            value: 0,
            nonce: account.nonce(),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

        bytes memory transactionData = abi.encodeWithSelector(
            Account.deploy.selector,
            deployParams,
            signatureForDeploy
        );

        IAccountAdmin.TransactionRequest memory txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 1_000_000,
            data: transactionData,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));
        admin.execute(txRequest, signatureForTx);

        // Deploy another contract with same salt.
        bytes memory signatureForTx2 = signTransactionRequest(txRequest, privateKey1, address(admin));
        vm.expectRevert();
        admin.execute(txRequest, signatureForTx2);
    }

    function test_revert_deploy_signatureNotFromIncumbentSigner() external {
        // Create account.
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Deploy contract with account.
        Account.DeployParams memory deployParams = IAccount.DeployParams({
            bytecode: type(DummyContract).creationCode,
            salt: keccak256("deploy"),
            value: 0,
            nonce: account.nonce(),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

        bytes memory transactionData = abi.encodeWithSelector(
            Account.deploy.selector,
            deployParams,
            signatureForDeploy
        );

        IAccountAdmin.TransactionRequest memory txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 1_000_000,
            data: transactionData,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signatureForTx = signTransactionRequest(txRequest, privateKey2, address(admin));
        vm.expectRevert("AccountAdmin: invalid signer.");
        admin.execute(txRequest, signatureForTx);
    }

    function test_revert_deploy_requestBeforeValidityStart() external {
        // Create account.
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Deploy contract with account.
        Account.DeployParams memory deployParams = IAccount.DeployParams({
            bytecode: type(DummyContract).creationCode,
            salt: keccak256("deploy"),
            value: 0,
            nonce: account.nonce(),
            validityStartTimestamp: 50,
            validityEndTimestamp: 100
        });
        bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

        bytes memory transactionData = abi.encodeWithSelector(
            Account.deploy.selector,
            deployParams,
            signatureForDeploy
        );

        IAccountAdmin.TransactionRequest memory txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 1_000_000,
            data: transactionData,
            validityStartTimestamp: 50,
            validityEndTimestamp: 100
        });
        bytes memory signatureForTx = signTransactionRequest(txRequest, privateKey2, address(admin));
        vm.expectRevert("AccountAdmin: request premature or expired.");
        vm.warp(txRequest.validityStartTimestamp - 1);
        admin.execute(txRequest, signatureForTx);
    }

    function test_revert_deploy_requestAfterValidityEnd() external {
        // Create account.
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Deploy contract with account.
        Account.DeployParams memory deployParams = IAccount.DeployParams({
            bytecode: type(DummyContract).creationCode,
            salt: keccak256("deploy"),
            value: 0,
            nonce: account.nonce(),
            validityStartTimestamp: 50,
            validityEndTimestamp: 100
        });
        bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

        bytes memory transactionData = abi.encodeWithSelector(
            Account.deploy.selector,
            deployParams,
            signatureForDeploy
        );

        IAccountAdmin.TransactionRequest memory txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 1_000_000,
            data: transactionData,
            validityStartTimestamp: 50,
            validityEndTimestamp: 100
        });
        bytes memory signatureForTx = signTransactionRequest(txRequest, privateKey2, address(admin));
        vm.expectRevert("AccountAdmin: request premature or expired.");
        vm.warp(txRequest.validityEndTimestamp);
        admin.execute(txRequest, signatureForTx);
    }

    /*///////////////////////////////////////////////////////////////
                Test action: Calling a smart contract.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev WALLET (account) performs a contract call.
     *
     *  Info passed by client:
     *      - transaction parameters: target, call data, gas, value, nonce
     *      - signature of intent from sigenr
     *      - validity start and end timestamps
     */

    Account internal account;
    address internal accountAddress;

    IAccountAdmin.TransactionRequest internal txRequest;
    bytes internal signatureForTx;

    address internal deployedContractAddr;

    function _setUp_execute() internal {
        {
            // Create account.
            IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
                signer: signer1,
                credentials: keccak256("1"),
                deploymentSalt: keccak256("1"),
                initialAccountBalance: 0,
                validityStartTimestamp: 0,
                validityEndTimestamp: 100
            });

            bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
            accountAddress = admin.createAccount(params, signature);

            account = Account(payable(accountAddress));
        }

        // Deploy contract with account.

        {
            Account.DeployParams memory deployParams = IAccount.DeployParams({
                bytecode: type(DummyContract).creationCode,
                salt: keccak256("deploy"),
                value: 0,
                nonce: account.nonce(),
                validityStartTimestamp: 0,
                validityEndTimestamp: 100
            });
            bytes memory signatureForDeploy = signDeploy(deployParams, privateKey1, accountAddress);

            bytes memory transactionData = abi.encodeWithSelector(
                Account.deploy.selector,
                deployParams,
                signatureForDeploy
            );

            txRequest = IAccountAdmin.TransactionRequest({
                signer: signer1,
                credentials: admin.credentialsOf(signer1),
                value: 0,
                gas: 1_000_000,
                data: transactionData,
                validityStartTimestamp: 0,
                validityEndTimestamp: 100
            });
            signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));
            admin.execute(txRequest, signatureForTx);

            deployedContractAddr = Create2.computeAddress(
                deployParams.salt,
                keccak256(abi.encodePacked(deployParams.bytecode)),
                accountAddress
            );

            assertEq(DummyContract(payable(deployedContractAddr)).deployer(), accountAddress);
        }
    }

    function test_state_execute() external {
        _setUp_execute();

        // Interact with deployed contract using account
        {
            // 1. Sending native tokens.
            vm.deal(signer1, 100 ether);
            assertEq(deployedContractAddr.balance, 0);

            Account.TransactionParams memory txParams1 = IAccount.TransactionParams({
                target: deployedContractAddr,
                data: "",
                nonce: account.nonce(),
                value: 1 ether,
                gas: 21000,
                validityStartTimestamp: 0,
                validityEndTimestamp: 100
            });
            bytes memory sigForWallet1 = signExecute(txParams1, privateKey1, accountAddress);
            bytes memory transactionData1 = abi.encodeWithSelector(Account.execute.selector, txParams1, sigForWallet1);

            txRequest.data = transactionData1;
            txRequest.value = 1 ether;

            signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));

            vm.prank(signer1);
            admin.execute{ value: 1 ether }(txRequest, signatureForTx);
            assertEq(deployedContractAddr.balance, 1 ether);
        }

        // 2. Interacting with contract.

        uint256 contractBalBefore = deployedContractAddr.balance;
        assertEq(contractBalBefore, 1 ether);
        assertEq(accountAddress.balance, 0);

        Account.TransactionParams memory txParams2 = IAccount.TransactionParams({
            target: deployedContractAddr,
            data: abi.encodeWithSelector(DummyContract.withdraw.selector),
            nonce: account.nonce(),
            value: 0,
            gas: 100_000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet2 = signExecute(txParams2, privateKey1, accountAddress);
        bytes memory transactionData2 = abi.encodeWithSelector(Account.execute.selector, txParams2, sigForWallet2);

        txRequest.data = transactionData2;
        txRequest.value = 0;

        bytes memory sigForEntrypoint2 = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        admin.execute(txRequest, sigForEntrypoint2);

        uint256 contractBalAfter = deployedContractAddr.balance;

        assertEq(accountAddress.balance, 1 ether);
        assertEq(contractBalAfter, 0);
    }

    function test_state_execute_noGasSpecified() external {
        _setUp_execute();

        // Interact with deployed contract using account
        {
            // 1. Sending native tokens.
            vm.deal(signer1, 100 ether);
            assertEq(deployedContractAddr.balance, 0);

            Account.TransactionParams memory txParams1 = IAccount.TransactionParams({
                target: deployedContractAddr,
                data: "",
                nonce: account.nonce(),
                value: 1 ether,
                gas: 21000,
                validityStartTimestamp: 0,
                validityEndTimestamp: 100
            });
            bytes memory sigForWallet1 = signExecute(txParams1, privateKey1, accountAddress);
            bytes memory transactionData1 = abi.encodeWithSelector(Account.execute.selector, txParams1, sigForWallet1);

            txRequest.data = transactionData1;
            txRequest.value = 1 ether;
            txRequest.gas = 0;

            signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));

            vm.prank(signer1);
            admin.execute{ value: 1 ether }(txRequest, signatureForTx);
            assertEq(deployedContractAddr.balance, 1 ether);
        }

        // 2. Interacting with contract.

        uint256 contractBalBefore = deployedContractAddr.balance;
        assertEq(contractBalBefore, 1 ether);
        assertEq(accountAddress.balance, 0);

        Account.TransactionParams memory txParams2 = IAccount.TransactionParams({
            target: deployedContractAddr,
            data: abi.encodeWithSelector(DummyContract.withdraw.selector),
            nonce: account.nonce(),
            value: 0,
            gas: 100_000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet2 = signExecute(txParams2, privateKey1, accountAddress);
        bytes memory transactionData2 = abi.encodeWithSelector(Account.execute.selector, txParams2, sigForWallet2);

        txRequest.data = transactionData2;
        txRequest.value = 0;
        txRequest.gas = 0;

        bytes memory sigForEntrypoint2 = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        admin.execute(txRequest, sigForEntrypoint2);

        uint256 contractBalAfter = deployedContractAddr.balance;

        assertEq(accountAddress.balance, 1 ether);
        assertEq(contractBalAfter, 0);
    }

    function test_revert_execute_executionRevertedInCalledContract() external {
        _setUp_execute();

        Account.TransactionParams memory txParams2 = IAccount.TransactionParams({
            target: deployedContractAddr,
            data: abi.encodeWithSelector(DummyContract.revert.selector),
            nonce: account.nonce(),
            value: 0,
            gas: 100_000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet2 = signExecute(txParams2, privateKey1, accountAddress);
        bytes memory transactionData2 = abi.encodeWithSelector(Account.execute.selector, txParams2, sigForWallet2);

        txRequest.data = transactionData2;
        txRequest.value = 0;

        bytes memory sigForEntrypoint2 = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        vm.expectRevert("Execution reverted.");
        admin.execute(txRequest, sigForEntrypoint2);
    }

    function test_revert_execute_signatureNotFromIncumbentSigner() external {
        _setUp_execute();

        Account.TransactionParams memory txParams2 = IAccount.TransactionParams({
            target: deployedContractAddr,
            data: abi.encodeWithSelector(DummyContract.revert.selector),
            nonce: account.nonce(),
            value: 0,
            gas: 100_000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet2 = signExecute(txParams2, privateKey2, accountAddress);
        bytes memory transactionData2 = abi.encodeWithSelector(Account.execute.selector, txParams2, sigForWallet2);

        txRequest.data = transactionData2;
        txRequest.value = 0;

        bytes memory sigForEntrypoint2 = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        vm.expectRevert("Account: invalid signer.");
        admin.execute(txRequest, sigForEntrypoint2);
    }

    function test_revert_execute_requestBeforeValidityStart() external {
        _setUp_execute();
        Account.TransactionParams memory txParams2 = IAccount.TransactionParams({
            target: deployedContractAddr,
            data: abi.encodeWithSelector(DummyContract.withdraw.selector),
            nonce: account.nonce(),
            value: 0,
            gas: 100_000,
            validityStartTimestamp: 50,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet2 = signExecute(txParams2, privateKey1, accountAddress);
        bytes memory transactionData2 = abi.encodeWithSelector(Account.execute.selector, txParams2, sigForWallet2);

        txRequest.data = transactionData2;
        txRequest.value = 0;

        bytes memory sigForEntrypoint2 = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        vm.expectRevert("Account: request premature or expired.");
        vm.warp(txParams2.validityStartTimestamp - 1);
        admin.execute(txRequest, sigForEntrypoint2);
    }

    function test_revert_execute_requestAfterValidityEnd() external {
        _setUp_execute();
        Account.TransactionParams memory txParams2 = IAccount.TransactionParams({
            target: deployedContractAddr,
            data: abi.encodeWithSelector(DummyContract.withdraw.selector),
            nonce: account.nonce(),
            value: 0,
            gas: 100_000,
            validityStartTimestamp: 50,
            validityEndTimestamp: 75
        });
        bytes memory sigForWallet2 = signExecute(txParams2, privateKey1, accountAddress);
        bytes memory transactionData2 = abi.encodeWithSelector(Account.execute.selector, txParams2, sigForWallet2);

        txRequest.data = transactionData2;
        txRequest.value = 0;

        bytes memory sigForEntrypoint2 = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        vm.expectRevert("Account: request premature or expired.");
        vm.warp(txParams2.validityEndTimestamp);
        admin.execute(txRequest, sigForEntrypoint2);
    }

    /*///////////////////////////////////////////////////////////////
                Test action: Storing and transferring tokens.
    //////////////////////////////////////////////////////////////*/

    function test_balances_receiveToken_nativeToken() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        vm.deal(signer1, 100 ether);

        assertEq(address(account).balance, 0);

        vm.prank(signer1);
        address(account).call{ value: 1 ether }("");

        assertEq(address(account).balance, 1 ether);
    }

    function test_balances_transferToken_nativeToken() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        vm.deal(signer1, 100 ether);
        vm.prank(signer1);
        address(account).call{ value: 1 ether }("");

        // Sending native tokens.
        address receiver = address(0x123);
        assertEq(receiver.balance, 0);

        Account.TransactionParams memory txParams1 = IAccount.TransactionParams({
            target: receiver,
            data: "",
            nonce: account.nonce(),
            value: 1 ether,
            gas: 21000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet1 = signExecute(txParams1, privateKey1, accountAddress);
        bytes memory transactionData1 = abi.encodeWithSelector(Account.execute.selector, txParams1, sigForWallet1);

        txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 1 ether,
            gas: 100_000,
            data: transactionData1,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        admin.execute{ value: 1 ether }(txRequest, signatureForTx);
        assertEq(receiver.balance, 1 ether);
    }

    function test_balances_receiveToken_ERC20() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        // Send ERC20 tokens to account.
        assertEq(erc20.balanceOf(accountAddress), 0);

        erc20.mint(accountAddress, 20 ether);

        assertEq(erc20.balanceOf(accountAddress), 20 ether);
    }

    function test_balances_transferToken_ERC20() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Send ERC20 tokens to account.
        erc20.mint(accountAddress, 20 ether);

        // Account transfers ERC20 tokens
        address receiver = address(0x123);
        assertEq(receiver.balance, 0);

        Account.TransactionParams memory txParams1 = IAccount.TransactionParams({
            target: address(erc20),
            data: abi.encodeWithSelector(ERC20.transfer.selector, receiver, 10 ether),
            nonce: account.nonce(),
            value: 0,
            gas: 50_000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet1 = signExecute(txParams1, privateKey1, accountAddress);
        bytes memory transactionData1 = abi.encodeWithSelector(Account.execute.selector, txParams1, sigForWallet1);

        AccountAdmin.TransactionRequest memory transactionRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 100_000,
            data: transactionData1,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        signatureForTx = signTransactionRequest(transactionRequest, privateKey1, address(admin));

        vm.prank(signer1);
        admin.execute(transactionRequest, signatureForTx);
        assertEq(erc20.balanceOf(receiver), 10 ether);
        assertEq(erc20.balanceOf(accountAddress), 10 ether);
    }

    function test_balances_receiveToken_ERC721() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        // Send E721 tokens to account.
        erc721.mint(accountAddress, 1);
        assertEq(erc721.ownerOf(0), accountAddress);
    }

    function test_balances_transferToken_ERC721() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Send E721 tokens to account.
        erc721.mint(accountAddress, 1);
        assertEq(erc721.ownerOf(0), accountAddress);

        // Transfer ERC721 token
        address receiver = address(0x123);

        Account.TransactionParams memory txParams1 = IAccount.TransactionParams({
            target: address(erc721),
            data: abi.encodeWithSelector(ERC721.transferFrom.selector, accountAddress, receiver, 0),
            nonce: account.nonce(),
            value: 0,
            gas: 50_000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet1 = signExecute(txParams1, privateKey1, accountAddress);
        bytes memory transactionData1 = abi.encodeWithSelector(Account.execute.selector, txParams1, sigForWallet1);

        txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 100_000,
            data: transactionData1,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        admin.execute(txRequest, signatureForTx);

        assertEq(erc721.ownerOf(0), receiver);
    }

    function test_balances_receiveToken_ERC1155() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        // Send ERC1155 tokens to account.
        erc1155.mint(accountAddress, 0, 100);
        assertEq(erc1155.balanceOf(accountAddress, 0), 100);
    }

    function test_balances_transferToken_ERC1155() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address accountAddress = admin.createAccount(params, signature);

        Account account = Account(payable(accountAddress));

        // Send ERC1155 tokens to account.
        erc1155.mint(accountAddress, 0, 100);
        assertEq(erc1155.balanceOf(accountAddress, 0), 100);

        // Transfer ERC1155 token
        address receiver = address(0x123);

        Account.TransactionParams memory txParams1 = IAccount.TransactionParams({
            target: address(erc1155),
            data: abi.encodeWithSelector(ERC1155.safeTransferFrom.selector, accountAddress, receiver, 0, 50, ""),
            nonce: account.nonce(),
            value: 0,
            gas: 50_000,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory sigForWallet1 = signExecute(txParams1, privateKey1, accountAddress);
        bytes memory transactionData1 = abi.encodeWithSelector(Account.execute.selector, txParams1, sigForWallet1);

        txRequest = IAccountAdmin.TransactionRequest({
            signer: signer1,
            credentials: admin.credentialsOf(signer1),
            value: 0,
            gas: 100_000,
            data: transactionData1,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        signatureForTx = signTransactionRequest(txRequest, privateKey1, address(admin));

        vm.prank(signer1);
        admin.execute(txRequest, signatureForTx);

        assertEq(erc1155.balanceOf(accountAddress, 0), 50);
        assertEq(erc1155.balanceOf(receiver, 0), 50);
    }
}
