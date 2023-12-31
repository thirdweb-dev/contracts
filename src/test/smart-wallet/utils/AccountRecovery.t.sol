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
}
