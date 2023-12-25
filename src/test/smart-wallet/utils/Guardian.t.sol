// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { IGuardian } from "contracts/prebuilts/account/interface/IGuardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { Test } from "forge-std/Test.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract GuardianTest is Test {
    Guardian public guardian;
    AccountGuardian public accountGuardian;
    address account;
    address public user = makeAddr("guardianUser");
    address public owner = msg.sender;
    uint256 public STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (, guardian, , accountGuardian, , , ) = deployer.run();
        vm.deal(user, STARTING_USER_BALANCE);
    }

    /////////////////////////////////////////
    ///// addVerifiedGuardian() tests //////
    ///////////////////////////////////////

    function testAddVerifiedGuardian() external {
        vm.prank(user);
        guardian.addVerifiedGuardian();

        vm.prank(owner);
        assert(guardian.getVerifiedGuardians().length > 0);
    }

    function testRevertIfZeroAddressBeingAddedAsGuardian() external {
        vm.prank(address(0));
        vm.expectRevert();
        guardian.addVerifiedGuardian();
    }

    function testRevertIfSameGuardianAddedTwice() external {
        vm.startPrank(user);
        guardian.addVerifiedGuardian();

        vm.expectRevert(abi.encodeWithSelector(IGuardian.GuardianAlreadyExists.selector, user));
        guardian.addVerifiedGuardian();
    }

    /////////////////////////////////////////
    ///// isVerifiedGuardian() test //////
    ///////////////////////////////////////

    function testIsGuardianVerified() external {
        // setup
        vm.prank(user);
        guardian.addVerifiedGuardian();

        assertEq(guardian.isVerifiedGuardian(user), true);
        assertEq(guardian.isVerifiedGuardian(owner), false);
    }

    ///////////////////////////////////////
    ///// removeVerifiedGuardian() test ///////////
    ///////////////////////////////////////

    function testremoveVerifiedGuardian() external {
        // Arrange
        vm.prank(user);
        guardian.addVerifiedGuardian();
        assertEq(guardian.isVerifiedGuardian(user), true);

        // Act
        vm.prank(user);
        guardian.removeVerifiedGuardian();

        //Assert
        assertEq(guardian.isVerifiedGuardian(user), false);
    }

    function testRevertOnRemovingGuardianThatDoesNotExist() external {
        // ACT
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IGuardian.NotAGuardian.selector, user));
        guardian.removeVerifiedGuardian();
    }

    ///////////////////////////////////////
    ///// getVerified() test //////////////
    ///////////////////////////////////////
    function testGetVerifiedGuardians() external {
        // SETUP
        vm.prank(user);
        guardian.addVerifiedGuardian();

        // ACT/assert
        vm.prank(owner);
        uint256 verifiedGuardiansCount = guardian.getVerifiedGuardians().length;
        assertEq(verifiedGuardiansCount, 1);
    }

    function testRevertIfNonOwnerCallsGetVerified() external {
        vm.prank(user);
        vm.expectRevert(Guardian.NotOwner.selector);
        guardian.getVerifiedGuardians();
    }

    /////////////////////////////////////////////
    ///// linkAccountToAccountGuardian() test ////
    //////////////////////////////////////////////

    function testLinkingAccountToAccountGuardian() external {
        // Setup
        guardian.linkAccountToAccountGuardian(address(account), address(accountGuardian));

        assertEq(guardian.getAccountGuardian(account), address(accountGuardian));
    }
}
