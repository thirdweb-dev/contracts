// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountRecovery } from "contracts/prebuilts/account/utils/AccountRecovery.sol";
import { IAccountRecovery } from "contracts/prebuilts/account/interface/IAccountRecovery.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";
import { Test } from "forge-std/Test.sol";

contract AccountRecoveryTest is Test {
    event AccountRecoveryRequestCreated();
    event EmailServiceGeneratingHashUsing(bytes token, uint256 nonce);
    event AccountRecoveryCreated();
    event GuardianSignatureRecorded(address indexed guardian);

    address user = makeAddr("user");

    address emailService = address(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720); // TODO: To be updated with the wallet address of the actual email
    string userEmail = "shiven@gmail.com";
    uint64 nonce = 38;
    bytes recoveryToken = abi.encodePacked(userEmail, emailService);

    address smartWallet;
    Guardian guardian;
    AccountRecovery accountRecovery;
    AccountGuardian accountGuardian;

    address firstGuard;
    uint256 firstGuardPK;
    address randomUser;
    uint256 randomUserPK;

    function setUp() external {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();

        // creating the smart account
        (smartWallet, , guardian, , accountGuardian, accountRecovery) = deployer.run();

        // adding guardians
        (firstGuard, firstGuardPK) = makeAddrAndKey("firstGuardian");
        (address secondGuard, uint256 secondGuardPK) = makeAddrAndKey("secondGuardian");
        (address thirdGuard, uint256 thirdGuardPK) = makeAddrAndKey("thirdGuardian");

        // guardians signing up in the system
        vm.prank(firstGuard);
        guardian.addVerifiedGuardian();
        vm.prank(secondGuard);
        guardian.addVerifiedGuardian();
        vm.prank(thirdGuard);
        guardian.addVerifiedGuardian();

        // the user alloting them as guardians for their smart wallet
        vm.startPrank(smartWallet);
        accountGuardian.addGuardian(firstGuard);
        accountGuardian.addGuardian(secondGuard);
        accountGuardian.addGuardian(thirdGuard);
        vm.stopPrank();

        (randomUser, randomUserPK) = makeAddrAndKey("randomUser");

        // commiting the recovery hash (representing the email recovery service)
        vm.startPrank(emailService);
        emit EmailServiceGeneratingHashUsing(recoveryToken, nonce);

        accountRecovery.commitEmailVerificationHash(recoveryToken, nonce);
        vm.stopPrank();
    }

    function testRevertWhenNonOwnerTriesToCreateRecoveryReq() external {
        vm.prank(randomUser);
        vm.expectRevert(IAccountRecovery.EmailVerificationFailed.selector);
        accountRecovery.generateRecoveryRequest(userEmail, abi.encode("randomToken"), 56); // 56 is a random nonce
    }

    function testRecoveryRequestGeneration() external {
        // creating a new Embedded wallet for the user
        address newWallet = makeAddr("newWallet");
        // Act/ Assert
        vm.prank(newWallet); // using the new wallet to send recovery req.
        vm.expectEmit();
        emit AccountRecoveryRequestCreated();
        accountRecovery.generateRecoveryRequest(userEmail, recoveryToken, nonce);
    }

    ////////////////////////////////////////////////////////
    // collectGuardianSignaturesOnRecoveryRequest //////////
    ////////////////////////////////////////////////////////

    function testRevertWhenNoRecoveryReqExists() external {
        bytes32 randomRequest = keccak256(abi.encode("randomFunction()"));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(firstGuardPK, randomRequest);
        bytes memory guardianSignature = abi.encodePacked(r, s, v);

        vm.prank(firstGuard);
        vm.expectRevert(abi.encodeWithSelector(IAccountRecovery.NoRecoveryRequestFound.selector, smartWallet));
        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(firstGuard, guardianSignature);
    }

    function testRevertWhenNotVerifiedGuardianSignsRecoveryRequest() external {
        // Setup
        // generating a recovery request
        vm.startPrank(user);
        accountRecovery.generateRecoveryRequest(userEmail, recoveryToken, nonce);
        bytes32 recoveryReq = accountRecovery.getRecoveryRequest();
        vm.stopPrank();

        // signing request by random user instead of a valid guardian
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomUserPK, recoveryReq);
        bytes memory randomUserSignature = abi.encodePacked(r, s, v);

        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(IAccountRecovery.NotAGuardian.selector, randomUser));
        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(randomUser, randomUserSignature);
    }

    function testCollectionOfGuardianSignOnRecoveryReq() external {
        vm.prank(user);
        accountRecovery.generateRecoveryRequest(userEmail, recoveryToken, nonce);

        bytes32 recoveryReq = accountRecovery.getRecoveryRequest();

        vm.startPrank(firstGuard);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(firstGuardPK, recoveryReq);
        bytes memory firstGuardSignature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, false, false, true);
        emit GuardianSignatureRecorded(firstGuard);

        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(firstGuard, firstGuardSignature);
        vm.stopPrank();
    }
}
