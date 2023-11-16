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
    address public guardian;
    uint256 private guardianPK;
    address public randomUser;
    uint256 private randomUserPK;

    uint256 constant GUARDIAN_STARTING_BALANCE = 10 ether;

    function setUp() external {
        (guardian, guardianPK) = makeAddrAndKey("guardian");
        (randomUser, randomUserPK) = makeAddrAndKey("random");

        deployer = new DeploySmartAccountUtilContracts();

        (accountFactory, account, guardianContract, accountLock, accountGuardian) = deployer.run();

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
        bytes memory randomUserSignature = abi.encodePacked(v, r, s);

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

        bytes memory signature = abi.encodePacked(v, r, s);

        // ACT
        accountLock.recordSignatureOnLockRequest(lockReqHash, signature);

        // Assert
        assertEq(accountLock.lockRequestToGuardianToSignature(lockReqHash, guardian), signature);

        vm.stopPrank();
    }

    /////////////////////////////////////////
    ////// lockRequestConcensysEvaluation tests //////
    ////////////////////////////////////////

    function testRevertWhenAccountLockRequestNotFound()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        vm.startPrank(guardian);
        vm.expectRevert(abi.encodeWithSelector(IAccountLock.AccountLockRequestNotFound.selector, account));
        accountLock.lockRequestConcensysEvaluation(account);
    }

    function testRevertWhenNonGuardianInitiatingLockReqConcensysEvalaution()
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
        accountLock.lockRequestConcensysEvaluation(account);
    }

    function testLockReqConcensysEvaluationWhenNoGuardianSigned()
        external
        addVerifiedGuardian
        addVerifiedGuardianAsAccountGuardian
    {
        vm.startPrank(guardian);
        accountLock.createLockRequest(account);

        bool lockReqConcensysResult = accountLock.lockRequestConcensysEvaluation(account);
        vm.stopPrank();

        assertEq(lockReqConcensysResult, false);
    }

    function testLockRequestConcensysEvaluation() external addVerifiedGuardian addVerifiedGuardianAsAccountGuardian {
        // SETUP
        vm.startPrank(guardian);

        bytes32 lockRequest = accountLock.createLockRequest(account);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(guardianPK, lockRequest);
        bytes memory signature = abi.encodePacked(v, r, s);

        address guardianRecovered = ECDSA.recover(lockRequest, signature); // throws error "ECDSA: invalid signature 'v' value"

        // address guardianRecovered = ECDSA.recover(lockRequest, v, r, s); // works fine!

        assertEq(guardian, guardianRecovered);

        // if ECDSA.recover(lockRequest, signature) doesn't work, we might have to send the (v, r, s) tuple instead of the signature object to `recordSignatureOnLockRequest(..)`
        accountLock.recordSignatureOnLockRequest(lockRequest, signature);

        // ACT
        bool lockReqConcensysResult = accountLock.lockRequestConcensysEvaluation(account);

        // Assert
        assertEq(lockReqConcensysResult, true);
    }
}
