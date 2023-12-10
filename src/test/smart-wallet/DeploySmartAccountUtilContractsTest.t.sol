// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Account } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract DeploySmartAccountUtilContractsTest is Test {
    AccountFactory accountFactory;
    address account;
    Guardian guardianContract;
    AccountLock accountLock;
    AccountGuardian accountGuardian;

    function setUp() external {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (accountFactory, account, guardianContract, accountLock, accountGuardian, , , ) = deployer.run();
    }

    function testIfSmartAccountUtilContractsDeployed() external {
        assert(
            address(accountFactory) != address(0) &&
                account != address(0) &&
                address(guardianContract) != address(0) &&
                address(accountLock) != address(0) &&
                address(accountGuardian) != address(0)
        );

        assert(guardianContract == accountFactory.guardian());
        assert(accountLock == accountFactory.accountLock());
        assert(accountGuardian == accountFactory.accountGuardian());
    }
}
