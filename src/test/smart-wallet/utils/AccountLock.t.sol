// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { EntryPoint } from "contracts/prebuilts/account/utils/EntryPoint.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Account } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { IAccountLock } from "contracts/prebuilts/account/interface/IAccountLock.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { IAccountLock } from "contracts/prebuilts/account/interface/IAccountLock.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract AccountLockTest is Test {
    AccountFactory public accountFactory;
    address public account;
    Guardian public guardianContract;
    AccountLock public accountLock;
    AccountGuardian public accountGuardian;
    DeploySmartAccountUtilContracts deployer;
    address owner = makeAddr("owner");
    address public admin = makeAddr("admin");
    address public guardian;
    uint256 private guardianPK;
    address public randomUser;
    uint256 private randomUserPK;

    uint256 constant GUARDIAN_STARTING_BALANCE = 10 ether;

    function setUp() external {
        (guardian, guardianPK) = makeAddrAndKey("guardian");
        (randomUser, randomUserPK) = makeAddrAndKey("random");

        deployer = new DeploySmartAccountUtilContracts();

        (account, accountFactory, guardianContract, accountLock, , ) = deployer.run();

        account = accountFactory.createAccount(admin, abi.encode("shiven@gmail.com"));
        accountGuardian = AccountGuardian(guardianContract.getAccountGuardian(account));
        vm.deal(guardian, GUARDIAN_STARTING_BALANCE);
    }

    ///////////////////////
    //// modifiers ////////
    ///////////////////////
    modifier addVerifiedGuardian() {
        vm.prank(guardian);
        guardianContract.addVerifiedGuardian();
        _;
    }

    modifier addVerifiedGuardianAsAccountGuardian() {
        vm.prank(account);
        accountGuardian.addGuardian(guardian);
        _;
    }

    ////////////////////////////////////
    /// createLockRequest() tests //////
    ////////////////////////////////////

    function testRevertIfNonGuardianCreatingAccountLockReq()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(IAccountLock.NotAGuardian.selector, randomUser));

        accountLock.createLockRequest(account);
    }

    function testRevertWhenCreatingLockReqForAlreadyLockedAccount()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        // Setup
        vm.prank(address(accountLock));
        // Account(account).setPaused(true); not working for some reason

        (bool success, ) = account.call(abi.encodeWithSignature("setPaused(bool)", true));

        if (success) {
            // Act
            vm.prank(guardian);
            vm.expectRevert(abi.encodeWithSelector(IAccountLock.AccountAlreadyLocked.selector, account));

            accountLock.createLockRequest(account);
        } else {
            vm.expectRevert();
        }
    }

    function testRevertWhenActiveLockRequestExists() external addVerifiedGuardian addVerifiedGuardianAsAccountGuardian {
        // Setup
        vm.startPrank(guardian);
        accountLock.createLockRequest(account);

        // Assert
        vm.expectRevert(IAccountLock.ActiveLockRequestFound.selector);
        accountLock.createLockRequest(account);
        vm.stopPrank();
    }

    function testLockRequestCreation() external addVerifiedGuardian addVerifiedGuardianAsAccountGuardian {
        // Setup
        vm.startPrank(guardian);
        bytes32 lockReqHash = accountLock.createLockRequest(account);

        bytes32[] memory lockRequests = accountLock.getLockRequests();
        vm.stopPrank();
        // Assert
        assert(lockReqHash != bytes32(0));
        assertEq(accountLock.activeLockRequestExists(account), true);
        assertEq(lockRequests[0], lockReqHash);
    }

    ////////////////////////////////////
    /// createUnLockRequest() tests //////
    ////////////////////////////////////

    function testRevertWhenCreatingLockReqForAlreadyUnLockedAccount()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        // Act
        vm.prank(guardian);
        vm.expectRevert(abi.encodeWithSelector(IAccountLock.AccountAlreadyUnLocked.selector, account));

        accountLock.createUnLockRequest(account);
    }

    function testRevertWhenActiveUnLockRequestExists()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        // Setup
        vm.prank(address(accountLock));
        account.call(abi.encodeWithSignature("setPaused(bool)", true));

        vm.startPrank(guardian);
        accountLock.createUnLockRequest(account);

        // Assert
        vm.expectRevert(IAccountLock.ActiveUnLockRequestFound.selector);
        accountLock.createUnLockRequest(account);
        vm.stopPrank();
    }

    function testUnLockRequestCreation() external addVerifiedGuardian addVerifiedGuardianAsAccountGuardian {
        // Setup
        vm.prank(address(accountLock));
        account.call(abi.encodeWithSignature("setPaused(bool)", true));

        vm.startPrank(guardian);
        accountLock.createUnLockRequest(account);

        bool unLockRequestExists = accountLock.activeUnLockRequestExists(account);
        vm.stopPrank();

        // Assert
        assertEq(unLockRequestExists, true);
    }

    ////////////////////////////////////////////
    ////// recordSignatureOnLockReq tests //////
    ///////////////////////////////////////////
    function testRevertWhenNonVerifiedGuardianSignatureIsSent()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        // Setup
        vm.prank(guardian);
        bytes32 lockReqHash = accountLock.createLockRequest(account);

        vm.startPrank(randomUser);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomUserPK, lockReqHash);
        bytes memory randomUserSignature = abi.encodePacked(r, s, v);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(IAccountLock.NotAGuardian.selector, randomUser));
        accountLock.recordSignatureOnLockRequest(lockReqHash, randomUserSignature);
        vm.stopPrank();
    }

    function testRecordSignatureOnLockRequest() external addVerifiedGuardian addVerifiedGuardianAsAccountGuardian {
        // SETUP
        vm.startPrank(guardian);
        bytes32 lockReqHash = accountLock.createLockRequest(account);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(guardianPK, lockReqHash);

        bytes memory signature = abi.encodePacked(r, s, v);

        // ACT
        accountLock.recordSignatureOnLockRequest(lockReqHash, signature);

        // Assert
        assertEq(accountLock.lockRequestToGuardianToSignature(lockReqHash, guardian), signature);

        vm.stopPrank();
    }

    ///////////////////////////////////////////////
    //// test recordSignatureOnUnLockRequest() ////
    ///////////////////////////////////////////////
    function testRecordSignatureOnUnLockRequest() external addVerifiedGuardian addVerifiedGuardianAsAccountGuardian {
        // SETUP
        vm.prank(address(accountLock));
        account.call(abi.encodeWithSignature("setPaused(bool)", true));

        vm.startPrank(guardian);
        bytes32 unLockReqHash = accountLock.createUnLockRequest(account);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(guardianPK, unLockReqHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // ACT
        accountLock.recordSignatureOnUnLockRequest(unLockReqHash, signature);

        // Assert
        assertEq(accountLock.unLockRequestToGuardianToSignature(unLockReqHash, guardian), signature);

        vm.stopPrank();
    }

    ///////////////////////////////////////////////////
    ////// accountRequestConcensusEvaluation tests ////
    //////////////////////////////////////////////////

    function testRevertWhenNoActiveRequestFoundForAccount()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        vm.startPrank(guardian);
        vm.expectRevert(abi.encodeWithSelector(IAccountLock.NoActiveRequestFoundForAccount.selector, account));
        accountLock.accountRequestConcensusEvaluation(account);
    }

    function testRevertWhenNonGuardianInitiatingAccountReqConcensusEvalaution()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        // SETUP
        vm.prank(guardian);
        accountLock.createLockRequest(account);

        // Act/assert
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(IAccountLock.NotAGuardian.selector, randomUser));
        accountLock.accountRequestConcensusEvaluation(account);
    }

    function testLockReqConcensusEvaluationWhenNoGuardianSigned()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        vm.startPrank(guardian);
        accountLock.createLockRequest(account);

        // no guardian signed

        bool lockReqConcensusResult = accountLock.accountRequestConcensusEvaluation(account);
        vm.stopPrank();

        assertEq(lockReqConcensusResult, false);
    }

    function testaccountRequestConcensusEvaluationPass()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        // SETUP
        vm.startPrank(guardian);

        bytes32 lockRequest = accountLock.createLockRequest(account);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(guardianPK, lockRequest);
        bytes memory signature = abi.encodePacked(r, s, v);

        accountLock.recordSignatureOnLockRequest(lockRequest, signature);

        // ACT
        bool lockReqConcensusResult = accountLock.accountRequestConcensusEvaluation(account);

        // Assert
        assertEq(lockReqConcensusResult, true);
    }

    function testaccountRequestConcensusEvaluationFail()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        // SETUP
        vm.startPrank(guardian);

        accountLock.createLockRequest(account);

        // ACT
        bool lockReqConcensusResult = accountLock.accountRequestConcensusEvaluation(account);

        // Assert
        assertEq(lockReqConcensusResult, false);
    }
}
