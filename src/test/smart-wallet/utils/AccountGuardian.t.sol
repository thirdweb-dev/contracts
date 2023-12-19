// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { EntryPoint } from "contracts/prebuilts/account/utils/EntryPoint.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { IAccountGuardian } from "contracts/prebuilts/account/interface/IAccountGuardian.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract AccountGuardianTest is Test {
    AccountGuardian accountGuardian;
    Guardian public guardianContract;
    AccountLock public accountLock;
    address owner = makeAddr("owner");
    address randomUser = makeAddr("randomUser");
    address guardian = makeAddr("guardian");

    event GuardianRemoved(address indexed guardian);

    function setUp() public {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (, , guardianContract, accountLock, accountGuardian, ) = deployer.run();
    }

    modifier addVerifiedGuardian() {
        vm.prank(guardian);
        guardianContract.addVerifiedGuardian();
        _;
    }

    //////////////////////////
    /// addGuardian() tests///
    //////////////////////////
    function testRevertIfGuardianAddedNotByOwner() public {
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(AccountGuardian.NotAuthorized.selector, randomUser));
        accountGuardian.addGuardian(randomUser);
    }

    function testRevertOnAddingUnverifiedGuardian() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IAccountGuardian.GuardianNotVerified.selector, randomUser));

        accountGuardian.addGuardian(randomUser);
    }

    function testAddGuardianAddsGuardianToList() public addVerifiedGuardian {
        // ACT
        vm.startPrank(owner);
        accountGuardian.addGuardian(guardian);

        address[] memory accountGuardians = accountGuardian.getAllGuardians();
        vm.stopPrank();

        assertEq(accountGuardians.length, 1);
        assertEq(accountGuardians[0], guardian);
    }

    /////////////////////////////
    /// removeGuardian() tests///
    /////////////////////////////

    function testRevertRemoveGuardianNotByOwner() external {
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(AccountGuardian.NotAuthorized.selector, randomUser));
        accountGuardian.removeGuardian(guardian);
    }

    function testRevertIfRemovingGuardianThatDoesNotExist() external {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IAccountGuardian.NotAGuardian.selector, guardian));
        accountGuardian.removeGuardian(guardian);
    }

    function testRemoveGuardianRemovesGuardianFromList() external addVerifiedGuardian {
        // SETUP
        vm.startPrank(owner);
        accountGuardian.addGuardian(guardian);

        // Act
        vm.expectEmit(true, false, false, false, address(accountGuardian));
        emit GuardianRemoved(guardian);
        accountGuardian.removeGuardian(guardian);

        // ASSERT
        address[] memory accountGuardians = accountGuardian.getAllGuardians();
        vm.stopPrank();
        assertEq(accountGuardians[0], address(0)); // the delete function in `removeGuardian()` will remove the guardian address but replace it with a zero address rather than removing the entry.
    }

    /////////////////////////////
    /// getAllGuardians() tests///
    /////////////////////////////

    function testRevertIfNotOwnerTriesToGetGuardians() external {
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(AccountGuardian.NotAuthorized.selector, randomUser));
        accountGuardian.getAllGuardians();
    }

    function testGetAllGuardians() external addVerifiedGuardian {
        // SETUP
        vm.startPrank(owner);
        accountGuardian.addGuardian(guardian);

        // ACT
        address[] memory accountGuardians = accountGuardian.getAllGuardians();
        vm.stopPrank();

        // Assert
        assertEq(accountGuardians[0], guardian);
    }

    ////////////////////////////////
    /// isAccountGuardain() tests///
    ////////////////////////////////

    function testIsAccountGuardian() external addVerifiedGuardian {
        //SETUP
        vm.startPrank(owner);
        accountGuardian.addGuardian(guardian);

        // Assert
        bool isAccountGuardian = accountGuardian.isAccountGuardian(guardian);
        vm.stopPrank();

        assertEq(isAccountGuardian, true);
    }
}
