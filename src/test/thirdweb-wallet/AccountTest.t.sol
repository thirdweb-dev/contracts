// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

////////// Target contract + interfaces //////////
import { Account, IAccount } from "contracts/thirdweb-wallet/Account.sol";
import { AccountAdmin, IAccountAdmin } from "contracts/thirdweb-wallet/AccountAdmin.sol";

////////// Test utils: signing //////////
import { AccountUtil, AccountAdminUtil, DummyContract } from "./AccountTestUtils.sol";

////////// Generic test imports //////////
import { ERC20, ERC721, ERC1155, Create2 } from "../utils/BaseTest.sol";

contract ThirdwebWalletTest is AccountUtil, AccountAdminUtil {
    bytes32 private constant SIGNER_ROLE = keccak256("SIGNER");

    AccountAdmin private accountAdmin;
    Account private account;

    uint256 public privateKey1 = 1234;
    uint256 public privateKey2 = 6789;
    uint256 public privateKey3 = 101112;

    address private signer1;
    address private signer2;
    address private signer3;

    function setUp() public override {
        super.setUp();

        // Deploy Architecture:Admin i.e. the entrypoint for a client.
        accountAdmin = new AccountAdmin();

        signer1 = vm.addr(privateKey1);
        signer2 = vm.addr(privateKey2);
        signer3 = vm.addr(privateKey3);
    }

    /*///////////////////////////////////////////////////////////////
                Test action: Creating an account.
    //////////////////////////////////////////////////////////////*/

    function test_state_createAccount() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: keccak256("salt"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        address accountAddress = accountAdmin.createAccount(params, signature);

        assertEq(Account(payable(accountAddress)).hasRole(SIGNER_ROLE, signer1), true);
        assertEq(Account(payable(accountAddress)).getRoleMemberCount(SIGNER_ROLE), 1);
        assertEq(Account(payable(accountAddress)).nonce(), 0);
        assertEq(Account(payable(accountAddress)).controller(), address(accountAdmin));
    }

    /// @dev Creates an account for a (signer, credentials) pair with a pre-determined address.
    function test_state_createAccount_deterministicAddress() external {
        bytes32 salt = keccak256("1");
        bytes memory bytecode = abi.encodePacked(
            type(Account).creationCode,
            abi.encode(address(accountAdmin), signer1)
        );
        bytes32 bytecodeHash = keccak256(bytecode);

        address predictedAddress = Create2.computeAddress(salt, bytecodeHash, address(accountAdmin));

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: salt,
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        address accountAddress = accountAdmin.createAccount(params, signature);

        assertEq(accountAddress, predictedAddress);
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

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        address accountAddress = accountAdmin.createAccount{ value: initialBalance }(params, signature);

        assertEq(accountAddress.balance, initialBalance);
    }

    /// @dev On creation of an account, event `AccountCreated` is emitted with: account, signer-of-account and creator (i.e. caller) address.
    function test_events_createAccount_AccountCreated() external {
        bytes32 salt = keccak256("1");
        bytes memory bytecode = abi.encodePacked(
            type(Account).creationCode,
            abi.encode(address(accountAdmin), signer1)
        );
        bytes32 bytecodeHash = keccak256(bytecode);

        address predictedAddress = Create2.computeAddress(salt, bytecodeHash, address(accountAdmin));

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            credentials: keccak256("1"),
            deploymentSalt: salt,
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));

        vm.expectEmit(true, true, true, true);
        emit AccountCreated(predictedAddress, signer1, signer2, params.credentials);
        vm.prank(signer2);
        accountAdmin.createAccount(params, signature);
    }

    // /// @dev Cannot create an account with empty credentials (bytes32(0)).
    // function test_revert_createAccount_emptyCredentials() external {
    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: bytes32(0), // empty credentials
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

    //     vm.expectRevert("AccountAdmin: invalid credentials.");
    //     admin.createAccount(params, signature);
    // }

    // /// @dev Must sent the exact native token value with transaction as the account's intended initial balance on creation.
    // function test_revert_createAccount_incorrectValueSentForInitialBalance() external {
    //     uint256 initialBalance = 1 ether;

    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: initialBalance,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

    //     vm.expectRevert("AccountAdmin: incorrect value sent.");
    //     admin.createAccount{ value: initialBalance - 1 }(params, signature); // Incorrect value sent.
    // }

    // /// @dev Must not repeat deployment salt.
    // function test_revert_createAccount_repeatingDeploymentSalt() external {
    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
    //     admin.createAccount(params, signature);

    //     IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
    //         signer: signer2,
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature2 = signCreateAccount(params2, privateKey2, address(admin));
    //     vm.expectRevert();
    //     admin.createAccount(params2, signature2);
    // }

    // /// @dev Signature of intent must be from the target signer for whom the account is created.
    // function test_revert_createAccount_signatureNotFromTargetSigner() external {
    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer2, // Signer2 is intended signer for account.
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin)); // Signature from Signer1 not Signer2

    //     vm.expectRevert("AccountAdmin: invalid signer.");
    //     admin.createAccount(params, signature);
    // }

    // /// @dev The signer must not already have an associated account.
    // function test_revert_createAccount_signerAlreadyHasAccount() external {
    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
    //     admin.createAccount(params, signature);

    //     IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
    //         signer: signer1, // Same signer
    //         credentials: keccak256("2"),
    //         deploymentSalt: keccak256("2"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature2 = signCreateAccount(params2, privateKey1, address(admin));
    //     vm.expectRevert("AccountAdmin: signer already has account.");
    //     admin.createAccount(params2, signature2);
    // }

    // /// @dev The signer must not already have an associated account.
    // function test_revert_createAccount_credentialsAlreadyUsed() external {
    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin));
    //     admin.createAccount(params, signature);

    //     IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: keccak256("1"), // Already used credentials
    //         deploymentSalt: keccak256("2"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: 0,
    //         validityEndTimestamp: 100
    //     });

    //     bytes memory signature2 = signCreateAccount(params2, privateKey1, address(admin));
    //     vm.expectRevert("AccountAdmin: credentials already used.");
    //     admin.createAccount(params2, signature2);
    // }

    // /// @dev The request to create account must not be processed at/after validity end timestamp.
    // function test_revert_createAccount_requestedAfterValidityEnd() external {
    //     uint128 validityStart = 50;
    //     uint128 validityEnd = 100;

    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: validityStart,
    //         validityEndTimestamp: validityEnd
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

    //     vm.warp(validityEnd);
    //     vm.expectRevert("AccountAdmin: request premature or expired.");
    //     admin.createAccount(params, signature);
    // }

    // /// @dev The request to create account must not be processed before validity start timestamp.
    // function test_revert_createAccount_requestedBeforeValidityStart() external {
    //     uint128 validityStart = 50;
    //     uint128 validityEnd = 100;

    //     IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
    //         signer: signer1,
    //         credentials: keccak256("1"),
    //         deploymentSalt: keccak256("1"),
    //         initialAccountBalance: 0,
    //         validityStartTimestamp: validityStart,
    //         validityEndTimestamp: validityEnd
    //     });

    //     bytes memory signature = signCreateAccount(params, privateKey1, address(admin));

    //     vm.warp(validityStart - 1);
    //     vm.expectRevert("AccountAdmin: request premature or expired.");
    //     admin.createAccount(params, signature);
    // }
}
