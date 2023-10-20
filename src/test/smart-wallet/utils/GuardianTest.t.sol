// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Guardian} from "contracts/prebuilts/account/utils/Guardian.sol";
import {IGuardian} from "contracts/prebuilts/account/interface/IGuardian.sol";
import {DeployGuardian} from "scripts/DeployGuardian.s.sol";
import {Test} from "forge-std/Test.sol";

contract GuardianTest is Test {
    Guardian public guardian;
    DeployGuardian public deployer;
    address public user = makeAddr('guardianUser');
    address public owner = msg.sender;
    uint256 public STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        deployer = new DeployGuardian();
        guardian = deployer.run();
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

        vm.expectRevert(
            abi.encodeWithSelector(
                IGuardian.GuardianAlreadyExists.selector,
                user
            ));
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
    ///// removeGuardian() test ///////////
    ///////////////////////////////////////

    function testRemoveGuardian() external {
        // Arrange
        vm.prank(user);
        guardian.addVerifiedGuardian();
        assertEq(guardian.isVerifiedGuardian(user), true);

        // Act
        vm.prank(user);
        guardian.removeGuardian();
        
        //Assert
        assertEq(guardian.isVerifiedGuardian(user), false);
    }

    function testRevertOnRemovingGuardianThatDoesNotExist() external {
        // ACT
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGuardian.NotAGuardian.selector,
                user
            )
        );
        guardian.removeGuardian();
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
}