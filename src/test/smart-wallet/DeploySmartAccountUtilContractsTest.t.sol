// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { AccountRecovery } from "contracts/prebuilts/account/utils/AccountRecovery.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract DeploySmartAccountUtilContractsTest is Test {
    address owner = makeAddr("owner");
    address smartAccount;
    AccountFactory accountFactory;
    Guardian guardianContract;
    AccountLock accountLock;
    AccountGuardian accountGuardian;
    AccountRecovery accountRecovery;

    function setUp() external {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (smartAccount, accountFactory, guardianContract, accountLock, accountGuardian, accountRecovery) = deployer
            .run();
    }

    function testIfSmartAccountUtilContractsDeployed() external {
        assert(
            smartAccount != address(0) &&
                address(accountFactory) != address(0) &&
                address(guardianContract) != address(0) &&
                address(accountLock) != address(0) &&
                address(accountGuardian) != address(0) &&
                address(accountRecovery) != address(0)
        );

        assert(guardianContract == accountFactory.guardian());
        assert(accountLock == accountFactory.accountLock());
    }
}
