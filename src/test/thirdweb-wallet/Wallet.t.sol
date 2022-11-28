// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Wallet, IWallet } from "contracts/thirdweb-wallet/Wallet.sol";
import { WalletEntrypoint, IWalletEntrypoint } from "contracts/thirdweb-wallet/WalletEntrypoint.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

import { BaseTest } from "../utils/BaseTest.sol";

/**
 *  Basic actions [WALLET]:
 *      - Deploy smart contracts
 *      - Make transactions on contracts
 *      - Sign messages
 *      - Own assets
 *
 *  Basic actions [WALLET_ENTRYPOINT]:
 *      - Create accounts.
 *      - Change signer of account.
 *      - Relay transaction to contract wallet.
 *
 *
 *  ARCHITECTURE: https://whimsical.com/smart-contract-wallet-71eMdPs2y2GnG21Aaq8qXS
 */

// TODO: All signature verification must account for both contract and EOA signers.

contract WalletUtil is BaseTest {
    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256(
            "TransactionParams(address target,bytes data,uint256 nonce,uint256 txGas,uint256 value,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
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
        Wallet.TransactionParams memory _params,
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
        Wallet.DeployParams memory _params,
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

contract WalletEntrypointUtil is BaseTest {
    bytes32 private constant CREATE_TYPEHASH =
        keccak256(
            "CreateAccountParams(address signer,bytes32 credentials,bytes32 deploymentSalt,uint256 initialAccountBalance,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant SIGNER_UPDATE_TYPEHASH =
        keccak256(
            "SignerUpdateParams(address account,address newSigner,address currentSigner,bytes32 newCredentials,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant TRANSACTION_TYPEHASH =
        keccak256("TransactionRequest(address signer,bytes32 credentials,uint256 value,uint256 gas,bytes data)");

    bytes32 internal nameHash = keccak256(bytes("thirdwebWallet_Admin"));
    bytes32 internal versionHash = keccak256(bytes("1"));
    bytes32 internal typehashEip712 =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function signCreateAccount(
        IWalletEntrypoint.CreateAccountParams memory _params,
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
        WalletEntrypoint.SignerUpdateParams memory _params,
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
        WalletEntrypoint.TransactionRequest memory _params,
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
                _params.data,
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

contract WalletEntrypointData {
    /// @notice Emitted when an account is created.
    event AccountCreated(address indexed account, address indexed signerOfAccount, address indexed creator);

    /// @notice Emitted when the signer for an account is updated.
    event SignerUpdated(address indexed account, address indexed newSigner);

    /// @notice Emitted on a call to an account.
    event CallResult(bool success, bytes result);
}

contract ThirdwebWalletTest is WalletUtil, WalletEntrypointUtil, WalletEntrypointData {
    WalletEntrypoint private admin;
    Wallet private wallet;

    uint256 public privateKey1 = 1234;
    uint256 public privateKey2 = 6789;

    address private signer1;
    address private signer2;

    function setUp() public override {
        super.setUp();

        // Deploy Architecture:Admin i.e. the entrypoint for a client.
        admin = new WalletEntrypoint();

        signer1 = vm.addr(privateKey1);
        signer2 = vm.addr(privateKey2);
    }

    /**
     *    REQUIREMENTS FOR TXS TO WALLET_ENTRYPOINT.
     *
     *  - Signature from Architecture:BurnerWallet (BW).
     *  - Payload signed by (BW) must contain a validity start and end timestamp.
     *  - Payload signed by (BW) must contain all argument values passed to the function other than the signature.
     */

    /**
     *    REQUIREMENTS FOR TXS FROM WALLET_ENTRYPOINT -> WALLET.
     *
     *  - Signature from Architecture:BurnerWallet (BW).
     *  - Signing (BW) must an approved signer of WALLET.
     *  - Payload signed by (BW) must contain a validity start and end timestamp.
     *  - Payload signed by (BW) must contain all argument values passed to the function other than the signature.
     */

    /**
     *    INVARIABLES FOR WALLET_ENTRYPOINT
     *
     *  - One and the same account associated with a signer, credentials and a (signer, credentials) pair.
     */

    /**
     *    INVARIABLES FOR WALLET
     *
     *  - One and only one WALLET_ENTRYPOINT approved to call into WALLET.
     *  - One and only one signer approved to control WALLET.
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
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);
        assertEq(Wallet(payable(account)).nonce(), 0);
        assertEq(Wallet(payable(account)).controller(), address(admin));
    }

    /// @dev Creates an account for a (signer, credentials) pair with a pre-determined address.
    function test_state_createAccount_deterministicAddress() external {
        bytes32 salt = keccak256("1");
        bytes memory bytecode = abi.encodePacked(type(Wallet).creationCode, abi.encode(address(admin), signer1));
        bytes32 bytecodeHash = keccak256(bytecode);

        address predictedAddress = Create2.computeAddress(salt, bytecodeHash, address(admin));

        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
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

        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
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
        bytes memory bytecode = abi.encodePacked(type(Wallet).creationCode, abi.encode(address(admin), signer1));
        bytes32 bytecodeHash = keccak256(bytecode);

        address predictedAddress = Create2.computeAddress(salt, bytecodeHash, address(admin));

        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
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
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: bytes32(0), // empty credentials
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.expectRevert("WalletEntrypoint: invalid credentials.");
        admin.createAccount(params, signature);
    }

    /// @dev Must sent the exact native token value with transaction as the account's intended initial balance on creation.
    function test_revert_createAccount_incorrectValueSentForInitialBalance() external {
        uint256 initialBalance = 1 ether;

        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: initialBalance,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.expectRevert("WalletEntrypoint: incorrect value sent.");
        admin.createAccount{ value: initialBalance - 1 }(params, signature); // Incorrect value sent.
    }

    /// @dev Must not repeat deployment salt.
    function test_revert_createAccount_repeatingDeploymentSalt() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        admin.createAccount(params, signature);

        IWalletEntrypoint.CreateAccountParams memory params2 = IWalletEntrypoint.CreateAccountParams({
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
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer2, // Signer2 is intended signer for account.
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin)); // Signature from Signer1 not Signer2

        vm.expectRevert("WalletEntrypoint: invalid signer.");
        admin.createAccount(params, signature);
    }

    /// @dev The signer must not already have an associated account.
    function test_revert_createAccount_signerAlreadyHasAccount() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        admin.createAccount(params, signature);

        IWalletEntrypoint.CreateAccountParams memory params2 = IWalletEntrypoint.CreateAccountParams({
            signer: signer1, // Same signer
            credentials: keccak256("2"),
            deploymentSalt: keccak256("2"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signCreateAccount(params2, privateKey1, address(admin));
        vm.expectRevert("WalletEntrypoint: signer already has account.");
        admin.createAccount(params2, signature2);
    }

    /// @dev The signer must not already have an associated account.
    function test_revert_createAccount_credentialsAlreadyUsed() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        admin.createAccount(params, signature);

        IWalletEntrypoint.CreateAccountParams memory params2 = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"), // Already used credentials
            deploymentSalt: keccak256("2"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signCreateAccount(params2, privateKey1, address(admin));
        vm.expectRevert("WalletEntrypoint: credentials already used.");
        admin.createAccount(params2, signature2);
    }

    /// @dev The request to create account must not be processed at/after validity end timestamp.
    function test_revert_createAccount_requestedAfterValidityEnd() external {
        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.warp(validityEnd);
        vm.expectRevert("WalletEntrypoint: request premature or expired.");
        admin.createAccount(params, signature);
    }

    /// @dev The request to create account must not be processed before validity start timestamp.
    function test_revert_createAccount_requestedBeforeValidityStart() external {
        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

        vm.warp(validityStart - 1);
        vm.expectRevert("WalletEntrypoint: request premature or expired.");
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
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);

        assertEq(Wallet(payable(account)).signer(), signer2);
    }

    function test_revert_changeSignerForAccount_newSignerAlreadyHasAccount() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer1,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("WalletEntrypoint: signer already has account.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_signatureNotFromIncumbentSigner() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey2, address(admin));

        vm.expectRevert("WalletEntrypoint: invalid signer.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_changingForIncorrectAccount() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: address(0x123),
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("WalletEntrypoint: incorrect account provided.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_emptyCredentials() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: bytes32(0),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("WalletEntrypoint: invalid credentials.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_credentialsAlreadyUsed() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("1"),
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.expectRevert("WalletEntrypoint: credentials already used.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_requestBeforeValidityStart() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.warp(validityStart - 1);
        vm.expectRevert("WalletEntrypoint: request premature or expired.");
        admin.changeSignerForAccount(signerUpdateParams, signatureForSignerUpdate);
    }

    function test_revert_changeSignerForAccount_requestAfterValidityEnd() external {
        IWalletEntrypoint.CreateAccountParams memory params = IWalletEntrypoint.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
        address account = admin.createAccount(params, signature);

        assertEq(Wallet(payable(account)).signer(), signer1);

        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IWalletEntrypoint.SignerUpdateParams memory signerUpdateParams = IWalletEntrypoint.SignerUpdateParams({
            account: account,
            currentSigner: signer1,
            newSigner: signer2,
            newCredentials: keccak256("2"),
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signatureForSignerUpdate = signSignerUpdate(signerUpdateParams, privateKey1, address(admin));

        vm.warp(validityEnd);
        vm.expectRevert("WalletEntrypoint: request premature or expired.");
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
    function test_state_deploy() external {}

    function test_state_deploy_deterministicAddress() external {}

    function test_balances_deploy_withInitialBalance() external {}

    function test_revert_deploy_incorrectValueSentForInitialBalance() external {}

    function test_revert_deploy_repeatingDeploymentSaltForSameContract() external {}

    function test_revert_deploy_signatureNotFromIncumbentSigner() external {}

    function test_revert_deploy_requestBeforeValidityStart() external {}

    function test_revert_deploy_requestAfterValidityEnd() external {}

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
    function test_state_execute() external {}

    function test_revert_execute_executionRevertedInCalledContract() external {}

    function test_revert_execute_signatureNotFromIncumbentSigner() external {}

    function test_revert_execute_requestBeforeValidityStart() external {}

    function test_revert_execute_requestAfterValidityEnd() external {}

    /*///////////////////////////////////////////////////////////////
                Test action: Storing and transferring tokens.
    //////////////////////////////////////////////////////////////*/

    function test_balances_receiveToken_nativeToken() external {}

    function test_balances_transferToken_nativeToken() external {}

    function test_balances_receiveToken_ERC20() external {}

    function test_balances_transferToken_ERC20() external {}

    function test_balances_receiveToken_ERC721() external {}

    function test_balances_transferToken_ERC721() external {}

    function test_balances_receiveToken_ERC1155() external {}

    function test_balances_transferToken_ERC1155() external {}
}
