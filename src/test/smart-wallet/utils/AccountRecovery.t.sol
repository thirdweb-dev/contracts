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
    event AccountRecoveryRequestConcensusFailed(address indexed account);
    event AccountRecoveryRequestConcensusAchieved(address indexed account);

    // creating a new Embedded wallet for the user
    address newEmbeddedWallet = makeAddr("newEmbeddedWallet");
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
    address secondGuard;
    uint256 secondGuardPK;
    address randomUser;
    uint256 randomUserPK;

    function _generateAccountRecoveryRequest(
        address sender,
        string memory email,
        bytes memory emailRecoveryToken,
        uint256 recoveryNonce
    ) internal returns (bytes32) {
        vm.prank(sender);
        accountRecovery.generateRecoveryRequest(email, emailRecoveryToken, recoveryNonce);

        return accountRecovery.getRecoveryRequest();
    }

    function _signAndReturnSignature(uint256 signerPK, bytes32 recoveryRequest) internal returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, recoveryRequest);
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }

    function setUp() external {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();

        // creating the smart account
        (smartWallet, , guardian, , accountGuardian, accountRecovery) = deployer.run();

        // adding guardians
        (firstGuard, firstGuardPK) = makeAddrAndKey("firstGuardian");
        (secondGuard, secondGuardPK) = makeAddrAndKey("secondGuardian");
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
        vm.expectRevert(IAccountRecovery.EmailVerificationFailed.selector);
        _generateAccountRecoveryRequest(randomUser, userEmail, abi.encode("randomToken"), 56); // 56 is random nonce
    }

    function testRecoveryRequestGeneration() external {
        // Act/ Assert
        vm.prank(newEmbeddedWallet); // using the new wallet to send recovery req.
        vm.expectEmit();
        emit AccountRecoveryRequestCreated();
        accountRecovery.generateRecoveryRequest(userEmail, recoveryToken, nonce);
    }

    ////////////////////////////////////////////////////////
    // collectGuardianSignaturesOnRecoveryRequest //////////
    ////////////////////////////////////////////////////////

    function testRevertWhenNoRecoveryReqExists() external {
        bytes32 randomRequest = keccak256(abi.encode("randomFunction()"));

        bytes memory guardianSignature = _signAndReturnSignature(firstGuardPK, randomRequest);

        vm.prank(firstGuard);
        vm.expectRevert(abi.encodeWithSelector(IAccountRecovery.NoRecoveryRequestFound.selector, smartWallet));
        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(firstGuard, guardianSignature);
    }

    function testRevertWhenNotVerifiedGuardianSignsRecoveryRequest() external {
        // Setup
        // generating a recovery request
        bytes32 recoveryReq = _generateAccountRecoveryRequest(newEmbeddedWallet, userEmail, recoveryToken, nonce);

        // signing request by random user instead of a valid guardian
        bytes memory randomUserSignature = _signAndReturnSignature(randomUserPK, recoveryReq);

        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(IAccountRecovery.NotAGuardian.selector, randomUser));
        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(randomUser, randomUserSignature);
    }

    function testCollectionOfGuardianSignOnRecoveryReq() external {
        bytes32 recoveryReq = _generateAccountRecoveryRequest(newEmbeddedWallet, userEmail, recoveryToken, nonce);

        vm.startPrank(firstGuard);
        bytes memory firstGuardSignature = _signAndReturnSignature(firstGuardPK, recoveryReq);

        vm.expectEmit(true, false, false, true);
        emit GuardianSignatureRecorded(firstGuard);

        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(firstGuard, firstGuardSignature);
        vm.stopPrank();
    }

    ////////////////////////////////////
    /// consensus evaluation tests /////
    ////////////////////////////////////

    function testConcensusFailedEvent() external {
        bytes32 recoveryReq = _generateAccountRecoveryRequest(newEmbeddedWallet, userEmail, recoveryToken, nonce);

        bytes memory firstGuardSignature = _signAndReturnSignature(firstGuardPK, recoveryReq);

        vm.prank(firstGuard);
        vm.expectEmit(true, false, false, false);
        emit AccountRecoveryRequestConcensusFailed(smartWallet);
        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(firstGuard, firstGuardSignature);
    }

    function testConcensusAcheivedEvent() external {
        bytes32 recoveryReq = _generateAccountRecoveryRequest(newEmbeddedWallet, userEmail, recoveryToken, nonce);

        // first guardian signing
        bytes memory firstGuardSignature = _signAndReturnSignature(firstGuardPK, recoveryReq);
        vm.prank(firstGuard);
        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(firstGuard, firstGuardSignature);

        // second guardian signing (Consensus should be achieved now)
        bytes memory secondGuardSignature = _signAndReturnSignature(secondGuardPK, recoveryReq);

        vm.prank(secondGuard);
        vm.expectEmit(true, false, false, false);
        emit AccountRecoveryRequestConcensusAchieved(smartWallet);
        accountRecovery.collectGuardianSignaturesOnRecoveryRequest(secondGuard, secondGuardSignature);
    }

    ////////////////////////////////////
    /// updating smart account owner ///
    ////////////////////////////////////
}
