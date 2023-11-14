// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { EntryPoint } from "contracts/prebuilts/account/utils/EntryPoint.sol";
import { Account } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { IAccountLock } from "contracts/prebuilts/account/interface/IAccountLock.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { IAccountLock } from "contracts/prebuilts/account/interface/IAccountLock.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract AccountLockTest is Test {
    address public account;
    Guardian public guardianContract;
    AccountLock public accountLock;
    AccountGuardian public accountGuardian;
    address owner = makeAddr("owner");
    address guardian = makeAddr("guardian");
    address randomUser = makeAddr("random");
    uint256 constant GUARDIAN_STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (, account, guardianContract, accountLock, accountGuardian) = deployer.run();

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
}
