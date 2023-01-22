// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

////////// Target contract + interfaces //////////
import { Account, IAccount } from "contracts/thirdweb-wallet/Account.sol";
import { AccountAdmin, IAccountAdmin } from "contracts/thirdweb-wallet/AccountAdmin.sol";

////////// Test utils: signing //////////
import { AccountUtil, AccountData, AccountAdminUtil, AccountAdminData, DummyContract, CounterContract } from "./AccountTestUtils.sol";

////////// Generic test imports //////////
import "../utils/BaseTest.sol";
import "contracts/TWProxy.sol";

contract ThirdwebWalletTest is BaseTest, AccountUtil, AccountData, AccountAdminUtil, AccountAdminData {
    bytes32 private constant SIGNER_ROLE = keccak256("SIGNER");
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;

    address private accountImplementation;
    address private accountAdminImplementation;

    AccountAdmin private accountAdmin;

    uint256 public privateKey1 = 1234;
    uint256 public privateKey2 = 6789;
    uint256 public privateKey3 = 101112;

    address private signer1;
    address private signer2;
    address private signer3;

    function setUp() public override {
        super.setUp();

        // Deploy Architecture:Admin i.e. the entrypoint for a client.
        accountImplementation = address(new Account());
        accountAdminImplementation = address(new AccountAdmin(accountImplementation));

        accountAdmin = AccountAdmin(
            address(
                new TWProxy(
                    accountAdminImplementation,
                    abi.encodeWithSelector(AccountAdmin.initialize.selector, forwarders())
                )
            )
        );

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
            accountId: keccak256("1"),
            deploymentSalt: keccak256("salt"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        address accountAddress = accountAdmin.createAccount(params, signature);

        assertEq(Account(payable(accountAddress)).hasRole(SIGNER_ROLE, signer1), false);
        assertEq(Account(payable(accountAddress)).hasRole(DEFAULT_ADMIN_ROLE, signer1), true);
        assertEq(Account(payable(accountAddress)).getRoleMemberCount(SIGNER_ROLE), 0);
        assertEq(Account(payable(accountAddress)).getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1);
        assertEq(Account(payable(accountAddress)).nonce(), 0);
        assertEq(Account(payable(accountAddress)).controller(), address(accountAdmin));

        address[] memory accountsOfSigner = accountAdmin.getAllAccountsOfSigner(signer1);
        assertEq(accountsOfSigner.length, 1);
        assertEq(accountsOfSigner[0], accountAddress);

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(accountAddress);
        assertEq(signersOfAccount.length, 1);
        assertEq(signersOfAccount[0], signer1);

        assertEq(accountAdmin.getAccount(signer1, params.accountId), accountAddress);
    }

    /// @dev Creates an account for a (signer, accountId) pair with a pre-determined address.
    function test_state_createAccount_deterministicAddress() external {
        bytes32 salt = keccak256("1");
        address relayer = address(0x12345);

        address predictedAddress = Clones.predictDeterministicAddress(
            accountImplementation,
            keccak256(abi.encode(salt, relayer)),
            address(accountAdmin)
        );

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
            deploymentSalt: salt,
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        vm.prank(relayer);
        address accountAddress = accountAdmin.createAccount(params, signature);

        assertEq(accountAddress, predictedAddress);
    }

    /// @dev Creates an account for a (signer, accountId) pair with an initial native token balance.
    function test_balances_createAccount_withInitialBalance() external {
        uint256 initialBalance = 1 ether;
        vm.deal(signer1, initialBalance);

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
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
        address relayer = address(0x12345);

        address predictedAddress = Clones.predictDeterministicAddress(
            accountImplementation,
            keccak256(abi.encode(salt, relayer)),
            address(accountAdmin)
        );

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
            deploymentSalt: salt,
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));

        vm.expectEmit(true, true, true, true);
        emit AccountCreated(predictedAddress, signer1, relayer, params.accountId);
        vm.prank(relayer);
        accountAdmin.createAccount(params, signature);
    }

    /// @dev Cannot create an account with empty accountId (bytes32(0)).
    function test_revert_createAccount_emptyaccountId() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: bytes32(0), // empty accountId
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));

        vm.expectRevert("AccountAdmin: invalid accountId.");
        accountAdmin.createAccount(params, signature);
    }

    /// @dev Must sent the exact native token value with transaction as the account's intended initial balance on creation.
    function test_revert_createAccount_incorrectValueSentForInitialBalance() external {
        uint256 initialBalance = 1 ether;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: initialBalance,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));

        vm.expectRevert("AccountAdmin: incorrect value sent.");
        accountAdmin.createAccount{ value: initialBalance - 1 }(params, signature); // Incorrect value sent.
    }

    /// @dev Must not repeat deployment salt.
    function test_revert_createAccount_repeatingDeploymentSalt() external {
        address relayer = address(0x12345);

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        vm.prank(relayer);
        accountAdmin.createAccount(params, signature);

        IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
            signer: signer2,
            accountId: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signCreateAccount(params2, privateKey2, address(accountAdmin));
        vm.expectRevert("ERC1167: create2 failed");
        vm.prank(relayer);
        accountAdmin.createAccount(params2, signature2);
    }

    /// @dev Signature of intent must be from the target signer for whom the account is created.
    function test_revert_createAccount_signatureNotFromTargetSigner() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer2, // Signer2 is intended signer for account.
            accountId: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin)); // Signature from Signer1 not Signer2

        vm.expectRevert("AccountAdmin: invalid signer.");
        accountAdmin.createAccount(params, signature);
    }

    /// @dev The signer must not already have an associated account.
    function test_revert_createAccount_accountIdAlreadyUsed() external {
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        accountAdmin.createAccount(params, signature);

        IAccountAdmin.CreateAccountParams memory params2 = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"), // Already used accountId
            deploymentSalt: keccak256("2"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signCreateAccount(params2, privateKey1, address(accountAdmin));
        vm.expectRevert("AccountAdmin: accountId already used.");
        accountAdmin.createAccount(params2, signature2);
    }

    /// @dev The request to create account must not be processed at/after validity end timestamp.
    function test_revert_createAccount_requestedAfterValidityEnd() external {
        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));

        vm.warp(validityEnd);
        vm.expectRevert("AccountAdmin: request premature or expired.");
        accountAdmin.createAccount(params, signature);
    }

    /// @dev The request to create account must not be processed before validity start timestamp.
    function test_revert_createAccount_requestedBeforeValidityStart() external {
        uint128 validityStart = 50;
        uint128 validityEnd = 100;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: signer1,
            accountId: keccak256("1"),
            deploymentSalt: keccak256("1"),
            initialAccountBalance: 0,
            validityStartTimestamp: validityStart,
            validityEndTimestamp: validityEnd
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));

        vm.warp(validityStart - 1);
        vm.expectRevert("AccountAdmin: request premature or expired.");
        accountAdmin.createAccount(params, signature);
    }

    /*///////////////////////////////////////////////////////////////
                Performing actions with created Account.
    //////////////////////////////////////////////////////////////*/

    Account private account;

    address private admin;
    bytes32 private adminAccountId = keccak256("1");

    address private nonAdmin;
    bytes32 private nonAdminAccountId = keccak256("2");

    address private newAdmin;
    bytes32 private newAdminAccountId = keccak256("3");

    DummyContract private dummy;
    CounterContract private counter;

    function _setUp_account() internal {
        dummy = new DummyContract();
        counter = new CounterContract();

        admin = signer1;
        nonAdmin = signer2;
        newAdmin = signer3;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: admin,
            accountId: adminAccountId,
            deploymentSalt: keccak256("salt"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey1, address(accountAdmin));
        address accountAddress = accountAdmin.createAccount(params, signature);

        account = Account(payable(accountAddress));

        assertEq(account.hasRole(account.DEFAULT_ADMIN_ROLE(), admin), true);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: Admin performs a transaction using Account.
    //////////////////////////////////////////////////////////////*/

    /// @dev Admin of Account executes a regular contract call.
    function test_state_execute_contractCallByAdmin() external {
        _setUp_account();

        uint256 number = 5;
        assertEq(account.nonce(), 0);
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        assertEq(account.nonce(), 1);
        assertEq(counter.getNumber(), number);
    }

    /// @dev Admin of Account executes a regular contract call; sends value.
    function test_state_execute_contractCallByAdmin_sendValue() external {
        _setUp_account();

        uint256 bal = 1 ether;

        assertEq(account.nonce(), 0);
        assertEq(address(dummy).balance, 0);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(dummy),
            data: "",
            nonce: account.nonce(),
            value: bal,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay{ value: bal }(admin, adminAccountId, bal, 0, data);

        assertEq(account.nonce(), 1);
        assertEq(address(dummy).balance, bal);
    }

    /// @notice Incorrect nonce when sending transaction request to Account.
    function test_revert_execute_contractCallByAdmin_incorrectNonce() external {
        _setUp_account();

        uint256 number = 5;
        assertEq(account.nonce(), 0);
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce() + 1,
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: incorrect nonce.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /// @notice Pre-mature transaction request sent to Account.
    function test_revert_execute_contractCallByAdmin_requestBeforeValidityStart() external {
        _setUp_account();

        uint256 number = 5;
        assertEq(account.nonce(), 0);
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 50,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.warp(params.validityStartTimestamp - 1);
        vm.expectRevert("Account: request premature or expired.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /// @notice Stale transaction request sent to Account.
    function test_revert_execute_contractCallByAdmin_requestAfterValidityEnd() external {
        _setUp_account();

        uint256 number = 5;
        assertEq(account.nonce(), 0);
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 50,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.warp(params.validityEndTimestamp);
        vm.expectRevert("Account: request premature or expired.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /// @notice Invalid signer signs transaction request to Account.
    function test_revert_execute_contractCallByAdmin_invalidSigner() external {
        _setUp_account();

        uint256 number = 5;
        assertEq(account.nonce(), 0);
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey2, address(account)); // Non admin signs transaction.

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: invalid signer.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: Admin adds a non-admin signer to account.
    //////////////////////////////////////////////////////////////*/

    function test_state_execute_addSignerToAccount() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.addSigner.selector, nonAdmin, nonAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        address[] memory accountsOfSigner1 = accountAdmin.getAllAccountsOfSigner(admin);
        assertEq(accountsOfSigner1.length, 1);
        assertEq(accountsOfSigner1[0], address(account));

        address[] memory accountsOfSigner2 = accountAdmin.getAllAccountsOfSigner(nonAdmin);
        assertEq(accountsOfSigner2.length, 1);
        assertEq(accountsOfSigner2[0], address(account));

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(address(account));
        assertEq(signersOfAccount.length, 2);
        assertEq(signersOfAccount[0], admin);
        assertEq(signersOfAccount[1], nonAdmin);

        assertEq(accountAdmin.getAccount(admin, adminAccountId), address(account));
        assertEq(accountAdmin.getAccount(nonAdmin, nonAdminAccountId), address(account));
    }

    function test_revert_execute_addSignerToAccount_signerAlreadyAdded() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.addSigner.selector, nonAdmin, nonAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        params.nonce = account.nonce();
        bytes memory signature2 = signExecute(params, privateKey1, address(account));
        data = abi.encodeWithSelector(Account.execute.selector, params, signature2);

        vm.expectRevert("Account: signer already exists.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: Admin removes a non-admin signer from account.
    //////////////////////////////////////////////////////////////*/

    function test_state_execute_removeSignerFromAccount() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.addSigner.selector, nonAdmin, nonAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        params.nonce = account.nonce();
        params.data = abi.encodeWithSelector(Account.removeSigner.selector, nonAdmin, nonAdminAccountId);
        bytes memory signature2 = signExecute(params, privateKey1, address(account));
        data = abi.encodeWithSelector(Account.execute.selector, params, signature2);

        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        address[] memory accountsOfSigner1 = accountAdmin.getAllAccountsOfSigner(admin);
        assertEq(accountsOfSigner1.length, 1);
        assertEq(accountsOfSigner1[0], address(account));

        address[] memory accountsOfSigner2 = accountAdmin.getAllAccountsOfSigner(nonAdmin);
        assertEq(accountsOfSigner2.length, 0);

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(address(account));
        assertEq(signersOfAccount.length, 1);
        assertEq(signersOfAccount[0], admin);

        assertEq(accountAdmin.getAccount(admin, adminAccountId), address(account));
        assertEq(accountAdmin.getAccount(nonAdmin, nonAdminAccountId), address(0));
    }

    function test_revert_execute_removeSignerFromAccount_signerAlreadyDNE() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.removeSigner.selector, nonAdmin, nonAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: signer already does not exist.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: Admin approves non-admin signer for target
        i.e. (fn sig + contract address)
    //////////////////////////////////////////////////////////////*/

    function _setUp_NonAdminForAccount() internal {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.addSigner.selector, nonAdmin, nonAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    function test_state_execute_approveSignerForTarget() external {
        _setUp_NonAdminForAccount();

        ////////// approve signer for target //////////

        bytes memory dataToRelay = abi.encodeWithSelector(
            Account.approveSignerForTarget.selector,
            nonAdmin,
            CounterContract.setNumber.selector,
            address(counter)
        );

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        ////////// signer calls target //////////

        uint256 number = 5;
        uint256 currentNonce = account.nonce();
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params2 = IAccount.TransactionParams({
            signer: nonAdmin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature2 = signExecute(params2, privateKey2, address(account)); // nonAdmin signs

        bytes memory data2 = abi.encodeWithSelector(Account.execute.selector, params2, signature2);
        accountAdmin.relay(nonAdmin, nonAdminAccountId, 0, 0, data2);

        assertEq(account.nonce(), currentNonce + 1);
        assertEq(counter.getNumber(), number);
    }

    function test_revert_execute_approveSignerForTarget_alreadyApproved() external {
        _setUp_NonAdminForAccount();

        ////////// approve signer for target //////////

        bytes memory dataToRelay = abi.encodeWithSelector(
            Account.approveSignerForTarget.selector,
            nonAdmin,
            CounterContract.setNumber.selector,
            address(counter)
        );

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        ////////// signer already approved for target //////////

        params.nonce = account.nonce();
        signature = signExecute(params, privateKey1, address(account));

        data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: already approved.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: Admin approves non-admin signer for contract.
    //////////////////////////////////////////////////////////////*/

    function test_state_execute_approveSignerForContract() external {
        _setUp_NonAdminForAccount();

        ////////// approve signer for target //////////

        bytes memory dataToRelay = abi.encodeWithSelector(
            Account.approveSignerForContract.selector,
            nonAdmin,
            address(counter)
        );

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        ////////// signer calls target //////////

        uint256 number = 5;
        uint256 currentNonce = account.nonce();
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params2 = IAccount.TransactionParams({
            signer: nonAdmin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature2 = signExecute(params2, privateKey2, address(account)); // nonAdmin signs

        bytes memory data2 = abi.encodeWithSelector(Account.execute.selector, params2, signature2);
        accountAdmin.relay(nonAdmin, nonAdminAccountId, 0, 0, data2);

        assertEq(account.nonce(), currentNonce + 1);
        assertEq(counter.getNumber(), number);
    }

    function test_revert_execute_approveSignerForContract_alreadyApproved() external {
        _setUp_NonAdminForAccount();

        ////////// approve signer for target //////////

        bytes memory dataToRelay = abi.encodeWithSelector(
            Account.approveSignerForContract.selector,
            nonAdmin,
            address(counter)
        );

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        ////////// signer already approved for target //////////

        params.nonce = account.nonce();
        signature = signExecute(params, privateKey, address(account));

        data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: already approved.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /*///////////////////////////////////////////////////////////////
            Test action: Admin adds another admin to account.
    //////////////////////////////////////////////////////////////*/

    function test_state_execute_addAdminToAccount() external {
        _setUp_account();

        ////////// Add admin //////////

        bytes memory dataToRelay = abi.encodeWithSelector(Account.addAdmin.selector, newAdmin, newAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        address[] memory accountsOfSigner1 = accountAdmin.getAllAccountsOfSigner(admin);
        assertEq(accountsOfSigner1.length, 1);
        assertEq(accountsOfSigner1[0], address(account));

        address[] memory accountsOfSigner2 = accountAdmin.getAllAccountsOfSigner(newAdmin);
        assertEq(accountsOfSigner2.length, 1);
        assertEq(accountsOfSigner2[0], address(account));

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(address(account));
        assertEq(signersOfAccount.length, 2);
        assertEq(signersOfAccount[0], admin);
        assertEq(signersOfAccount[1], newAdmin);

        assertEq(accountAdmin.getAccount(admin, adminAccountId), address(account));
        assertEq(accountAdmin.getAccount(newAdmin, newAdminAccountId), address(account));

        ////////// New admin performs transaction //////////

        uint256 number = 5;
        uint256 currentNonce = account.nonce();
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params2 = IAccount.TransactionParams({
            signer: newAdmin,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature2 = signExecute(params2, privateKey3, address(account)); // newAdmin signs

        bytes memory data2 = abi.encodeWithSelector(Account.execute.selector, params2, signature2);
        accountAdmin.relay(newAdmin, newAdminAccountId, 0, 0, data2);

        assertEq(account.nonce(), currentNonce + 1);
        assertEq(counter.getNumber(), number);
    }

    function test_revert_execute_addAdminToAccount_adminAlreadyAdded() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.addAdmin.selector, newAdmin, newAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        params.nonce = account.nonce();
        bytes memory signature2 = signExecute(params, privateKey1, address(account));
        data = abi.encodeWithSelector(Account.execute.selector, params, signature2);

        vm.expectRevert("Account: admin already exists.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: Admin removes another admin from account.
    //////////////////////////////////////////////////////////////*/

    function test_state_execute_removeAdminFromAccount() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.addAdmin.selector, newAdmin, newAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        params.nonce = account.nonce();
        params.data = abi.encodeWithSelector(Account.removeAdmin.selector, newAdmin, newAdminAccountId);
        bytes memory signature2 = signExecute(params, privateKey1, address(account));
        data = abi.encodeWithSelector(Account.execute.selector, params, signature2);

        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        address[] memory accountsOfSigner1 = accountAdmin.getAllAccountsOfSigner(admin);
        assertEq(accountsOfSigner1.length, 1);
        assertEq(accountsOfSigner1[0], address(account));

        address[] memory accountsOfSigner2 = accountAdmin.getAllAccountsOfSigner(newAdmin);
        assertEq(accountsOfSigner2.length, 0);

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(address(account));
        assertEq(signersOfAccount.length, 1);
        assertEq(signersOfAccount[0], admin);

        assertEq(accountAdmin.getAccount(admin, adminAccountId), address(account));
        assertEq(accountAdmin.getAccount(newAdmin, newAdminAccountId), address(0));
    }

    function test_revert_execute_removeAdminFromAccount_adminAlreadyRemoved() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.removeAdmin.selector, newAdmin, newAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: admin already does not exist.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: Admin deploys a smart contract with account.
    //////////////////////////////////////////////////////////////*/

    function test_state_execute_deploy() external {
        _setUp_account();

        address relayer = address(0x12345);

        bytes32 salt = keccak256("1");
        bytes memory bytecode = type(DummyContract).creationCode;

        bytes memory dataToRelay = abi.encodeWithSelector(Account.deploy.selector, bytecode, salt, 0);

        address predictedAddress = Create2.computeAddress(
            keccak256(abi.encode(salt, relayer)),
            keccak256(abi.encodePacked(bytecode)),
            address(account)
        );

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.prank(relayer, relayer);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        assertEq(DummyContract(payable(predictedAddress)).deployer(), address(account));
    }

    function test_revert_execute_deploy_repeatSalt() external {
        _setUp_account();

        address relayer = address(0x12345);

        bytes32 salt = keccak256("1");
        bytes memory bytecode = type(DummyContract).creationCode;

        bytes memory dataToRelay = abi.encodeWithSelector(Account.deploy.selector, bytecode, salt, 0);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.prank(relayer, relayer);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        params.nonce = account.nonce();
        bytes memory signature2 = signExecute(params, privateKey1, address(account));
        bytes memory data2 = abi.encodeWithSelector(Account.execute.selector, params, signature2);

        vm.prank(relayer, relayer);
        vm.expectRevert("Create2: Failed on deploy");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data2);
    }

    /*///////////////////////////////////////////////////////////////
        Test action: One Account is a signer on another Account.
    //////////////////////////////////////////////////////////////*/

    function test_state_execute_addAccountAsSigner() external {
        ///// Deploy Account to add another Account as a signer. /////
        _setUp_account();

        ///// Create another Account /////

        address altAdmin = signer2;

        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: altAdmin,
            accountId: keccak256("1"),
            deploymentSalt: keccak256("salt"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccount(params, privateKey2, address(accountAdmin));
        vm.prank(altAdmin);
        address altAccount = accountAdmin.createAccount(params, signature);

        ///// Add Alt Account to original Account as a signer (admin, for simplicity) /////
        bytes32 altAccountAccountId = keccak256("11");
        IAccount.TransactionParams memory params2 = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: abi.encodeWithSelector(Account.addAdmin.selector, altAccount, altAccountAccountId),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature2 = signExecute(params2, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params2, signature2);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        ///// Alt Account signs (in the sense of EIP 1271) and sends tx instruction to original Account /////

        uint256 number = 5;
        uint256 currentNonce = account.nonce();
        assertEq(counter.getNumber(), 0);

        IAccount.TransactionParams memory params3 = IAccount.TransactionParams({
            signer: altAccount,
            target: address(counter),
            data: abi.encodeWithSelector(CounterContract.setNumber.selector, number),
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature3 = signExecute(params3, privateKey2, address(altAccount)); // signer on alt account signs

        bytes memory data2 = abi.encodeWithSelector(Account.execute.selector, params3, signature3);
        accountAdmin.relay(altAccount, altAccountAccountId, 0, 0, data2);

        assertEq(account.nonce(), currentNonce + 1);
        assertEq(counter.getNumber(), number);
    }

    /*///////////////////////////////////////////////////////////////
    Test action: an Account creates another Account on AccountAdmin.
    //////////////////////////////////////////////////////////////*/

    function test_state_createAccount_byAnotherAccount() external {
        ///// Deploy Account to use to create another account. /////
        _setUp_account();

        ///// Create another Account /////
        IAccountAdmin.CreateAccountParams memory params = IAccountAdmin.CreateAccountParams({
            signer: address(account),
            accountId: keccak256("xyz"),
            deploymentSalt: keccak256("saltsalt"),
            initialAccountBalance: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signCreateAccountViaAccount(params, privateKey1, address(account));

        vm.prank(admin);
        address altAccount = accountAdmin.createAccount(params, signature);

        assertEq(Account(payable(altAccount)).hasRole(SIGNER_ROLE, address(account)), false);
        assertEq(Account(payable(altAccount)).hasRole(DEFAULT_ADMIN_ROLE, address(account)), true);
        assertEq(Account(payable(altAccount)).getRoleMemberCount(SIGNER_ROLE), 0);
        assertEq(Account(payable(altAccount)).getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1);
        assertEq(Account(payable(altAccount)).nonce(), 0);
        assertEq(Account(payable(altAccount)).controller(), address(accountAdmin));

        address[] memory accountsOfSigner = accountAdmin.getAllAccountsOfSigner(address(account));
        assertEq(accountsOfSigner.length, 1);
        assertEq(accountsOfSigner[0], altAccount);

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(altAccount);
        assertEq(signersOfAccount.length, 1);
        assertEq(signersOfAccount[0], address(account));

        assertEq(accountAdmin.getAccount(address(account), params.accountId), altAccount);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_C_1_fixed() public {
        _setUp_account();

        address recipient = address(0xb0b);
        vm.deal(address(recipient), 0 ether);
        vm.deal(address(account), 100 ether); // send ether into account

        bytes memory dataToRelay = abi.encodeWithSelector(""); // vanilla call

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(recipient),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 100 ether,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);

        // --------Revert relay call with eth coming from this test contract--------

        // vm.expectRevert("Account: incorrect value sent."); // revert in _validateCallConditions()
        // Don't send eth in with `{value: 100 ether}`. We want the ether to come from `account`, not this test contract
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        assertEq(recipient.balance, 100 ether);
        assertEq(address(account).balance, 0);

        // --------Successful relay call with eth coming from this test contract--------

        // vm.deal(address(this), 100 ether);

        // accountAdmin.relay{ value: 100 ether }(admin, adminAccountId, 100 ether, 0, data);

        // assertEq(recipient.balance, 100 ether);
        // assertEq(address(account).balance, 100 ether); // ether still in account
        // assertEq(address(this).balance, 0 ether); // ether in recipient came from test contract
    }

    function testEthStuckExecute_fixed() public {
        _setUp_account();

        address recipient = address(0xb0b);
        vm.deal(address(recipient), 0 ether);
        vm.deal(address(account), 100 ether); // send ether into account

        bytes memory dataToRelay = abi.encodeWithSelector(""); // vanilla call

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(recipient),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 100 ether,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey, address(account));

        // --------Revert execute call with eth coming from this test contract--------

        // vm.expectRevert("Account: incorrect value sent."); // revert in _validateCallConditions()
        // Don't send eth in with `{value: 100 ether}`. We want the ether to come from `account`, not this test contract
        account.execute(params, signature);

        assertEq(recipient.balance, 100 ether);
        assertEq(address(account).balance, 0);

        // --------Successful direct execute call with ether coming from this test contract

        // vm.deal(address(this), 100 ether);

        // account.execute{ value: 100 ether }(params, signature);

        // assertEq(recipient.balance, 100 ether);
        // assertEq(address(account).balance, 100 ether); // ether still in account
        // assertEq(address(this).balance, 0 ether); // ether in recipient came from test contract
    }

    function test_H_1_fixed() external {
        _setUp_account();

        bytes memory dataToRelay = abi.encodeWithSelector(Account.removeAdmin.selector, admin, adminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: must have at least one admin.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        assertEq(account.hasRole(DEFAULT_ADMIN_ROLE, address(admin)), true);

        address[] memory accountsOfSigner = accountAdmin.getAllAccountsOfSigner(admin);
        assertEq(accountsOfSigner.length, 1);

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(address(account));
        assertEq(signersOfAccount.length, 1);
    }

    function test_M_1_fixed() external {
        _setUp_account();

        // ------------- ADD newAdmin as Signer -------------------/
        bytes memory dataToRelay = abi.encodeWithSelector(Account.addSigner.selector, newAdmin, newAdminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        // ------------- ADD newAdmin as Admin -------------------/
        bytes memory dataToRelay2 = abi.encodeWithSelector(Account.addAdmin.selector, newAdmin, newAdminAccountId);

        IAccount.TransactionParams memory params2 = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay2,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature2 = signExecute(params2, privateKey1, address(account));

        bytes memory data2 = abi.encodeWithSelector(Account.execute.selector, params2, signature2);
        vm.expectRevert("Account: signer already has SIGNER_ROLE.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data2);

        address[] memory accountsOfSigner1 = accountAdmin.getAllAccountsOfSigner(admin);
        assertEq(accountsOfSigner1.length, 1);
        assertEq(accountsOfSigner1[0], address(account));

        address[] memory accountsOfSigner2 = accountAdmin.getAllAccountsOfSigner(newAdmin);
        assertEq(accountsOfSigner2.length, 1);
        assertEq(accountsOfSigner2[0], address(account));

        address[] memory signersOfAccount = accountAdmin.getAllSignersOfAccount(address(account));
        assertEq(signersOfAccount.length, 2);
        assertEq(signersOfAccount[0], admin);
        assertEq(signersOfAccount[1], newAdmin);

        assertEq(accountAdmin.getAccount(admin, adminAccountId), address(account));
        assertEq(accountAdmin.getAccount(newAdmin, newAdminAccountId), address(account));

        // ------------- REMOVE newAdmin from being Signer -------------------/
        bytes memory dataToRelay3 = abi.encodeWithSelector(Account.removeSigner.selector, newAdmin, newAdminAccountId);

        IAccount.TransactionParams memory params3 = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay3,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });

        bytes memory signature3 = signExecute(params3, privateKey1, address(account));

        bytes memory data3 = abi.encodeWithSelector(Account.execute.selector, params3, signature3);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data3);

        accountsOfSigner1 = accountAdmin.getAllAccountsOfSigner(admin);
        assertEq(accountsOfSigner1.length, 1);
        assertEq(accountsOfSigner1[0], address(account));

        accountsOfSigner2 = accountAdmin.getAllAccountsOfSigner(newAdmin);
        assertEq(accountsOfSigner2.length, 0);

        signersOfAccount = accountAdmin.getAllSignersOfAccount(address(account));
        assertEq(signersOfAccount.length, 1);
        assertEq(signersOfAccount[0], admin);

        assertEq(account.hasRole(DEFAULT_ADMIN_ROLE, address(newAdmin)), false);
        assertEq(accountAdmin.getAccount(newAdmin, newAdminAccountId), address(0));
    }

    function test_M_2_fixed() external {
        _setUp_account();

        //----- Add non Admin Signer ---------//
        bytes memory dataToRelay = abi.encodeWithSelector(Account.addSigner.selector, nonAdmin, adminAccountId);

        IAccount.TransactionParams memory params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        bytes memory signature = signExecute(params, privateKey1, address(account));

        bytes memory data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);

        ////////// approve signer for target //////////

        dataToRelay = abi.encodeWithSelector(Account.approveSignerForContract.selector, nonAdmin, address(account));

        params = IAccount.TransactionParams({
            signer: admin,
            target: address(account),
            data: dataToRelay,
            nonce: account.nonce(),
            value: 0,
            gas: 0,
            validityStartTimestamp: 0,
            validityEndTimestamp: 100
        });
        signature = signExecute(params, privateKey1, address(account));

        data = abi.encodeWithSelector(Account.execute.selector, params, signature);
        vm.expectRevert("Account: can't approve signer for entire account contract.");
        accountAdmin.relay(admin, adminAccountId, 0, 0, data);
    }
}
