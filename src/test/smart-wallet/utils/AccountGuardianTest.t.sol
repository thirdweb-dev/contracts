// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";
import { IAccountGuardian } from "contracts/prebuilts/account/interface/IAccountGuardian.sol";

contract AccountGuardianTest is Test {
    AccountGuardian accountGuardian;
    Guardian public guardianContract;
    address randomUser = makeAddr("randomUser");
    address guardian = makeAddr("guardian");

    event GuardianRemoved(address indexed guardian);

    function setUp() public {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (, , accountGuardian, guardianContract, ) = deployer.run();
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
        vm.expectRevert(AccountGuardian.NotOwnerOrAccountLock.selector);
        accountGuardian.addGuardian(randomUser);
    }

    function testRevertOnAddingUnverifiedGuardian() public {
        vm.expectRevert(abi.encodeWithSelector(IAccountGuardian.GuardianNotVerified.selector, randomUser));

        accountGuardian.addGuardian(randomUser);
    }

    function testAddGuardianAddsGuardianToList() public addVerifiedGuardian {
        // ACT
        accountGuardian.addGuardian(guardian);

        address[] memory accountGuardians = accountGuardian.getAllGuardians();

        assertEq(accountGuardians.length, 1);
        assertEq(accountGuardians[0], guardian);
    }

    /////////////////////////////
    /// removeGuardian() tests///
    /////////////////////////////

    function testRevertRemoveGuardianNotByOwner() external {
        vm.prank(randomUser);
        vm.expectRevert(AccountGuardian.NotOwnerOrAccountLock.selector);
        accountGuardian.removeGuardian(guardian);
    }

    function testRevertIfRemovingGuardianThatDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(IAccountGuardian.NotAGuardian.selector, guardian));
        accountGuardian.removeGuardian(guardian);
    }

    function testRemoveGuardianRemovesGuardianFromList() external addVerifiedGuardian {
        // SETUP
        accountGuardian.addGuardian(guardian);

        // Act
        vm.expectEmit(true, false, false, false, address(accountGuardian));
        emit GuardianRemoved(guardian);
        accountGuardian.removeGuardian(guardian);

        // ASSERT
        address[] memory accountGuardians = accountGuardian.getAllGuardians();
        assertEq(accountGuardians[0], address(0)); // the delete function in `removeGuardian()` will remove the guardian address but replace it with a zero address rather than removing the entry.
    }

    /////////////////////////////
    /// getAllGuardians() tests///
    /////////////////////////////

    function testRevertIfNotOwnerTriesToGetGuardians() external {
        vm.prank(randomUser);
        vm.expectRevert(AccountGuardian.NotOwnerOrAccountLock.selector);
        accountGuardian.getAllGuardians();
    }

    function testGetAllGuardians() external addVerifiedGuardian {
        // SETUP
        accountGuardian.addGuardian(guardian);

        // ACT
        address[] memory accountGuardians = accountGuardian.getAllGuardians();

        // Assert
        assertEq(accountGuardians[0], guardian);
    }
}
