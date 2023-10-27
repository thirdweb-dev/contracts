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
    function run() external returns (AccountFactory, address, AccountGuardian, Guardian, AccountLock) {
        EntryPoint entryPoint = new EntryPoint();

        AccountFactory accountFactory = new AccountFactory(entryPoint);

        Guardian guardianContract = accountFactory.guardian();
        AccountLock accountLock = accountFactory.accountLock();

        address account = accountFactory.createAccount(address(this), "");

        AccountGuardian accountGuardian = new AccountGuardian(guardianContract, accountLock, account);

        return (accountFactory, account, accountGuardian, guardianContract, accountLock);
    }
}
