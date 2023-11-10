// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { Script } from "forge-std/Script.sol";
import { EntryPoint } from "contracts/prebuilts/account/utils/EntryPoint.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Account } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";

contract DeploySmartAccountUtilContracts is Script {
    address admin = makeAddr("admin");

    function run() external returns (AccountFactory, address, Guardian, AccountLock, AccountGuardian) {
        EntryPoint entryPoint = new EntryPoint();
        AccountFactory accountFactory = new AccountFactory(entryPoint);
        address account = accountFactory.createAccount(admin, "");

        Guardian guardianContract = accountFactory.guardian();
        AccountLock accountLock = accountFactory.accountLock();
        AccountGuardian accountGuardian = accountFactory.accountGuardian();

        return (accountFactory, account, guardianContract, accountLock, accountGuardian);
    }
}
