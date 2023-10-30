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
    address user = makeAddr("user");

    function run() external returns (AccountFactory, address, AccountGuardian, Guardian, AccountLock) {
        EntryPoint entryPoint = new EntryPoint();

        /// @dev AccountFactory create a new Account instance and passes the address to BaseFactory to be used in the `createAccount(..)` function for adding salt, and some processing before the processed Account addresss is returned.

        AccountFactory accountFactory = new AccountFactory(entryPoint);

        /// @dev As pointed out in the previous Natspec, the returned address will not be a processed Account address, hence calling `BaseAccountFactory.getAllAccounts()` returned by BaseAccountFactory.
        address[] memory accounts = accountFactory.getAllAccounts();
        address account = accounts[0]; // processed account address by BaseAccountFactory

        Guardian guardianContract = accountFactory.guardian();
        AccountLock accountLock = accountFactory.accountLock();
        // AccountGuardian accountGuardian = accountFactory.accountGuardian();

        return (accountFactory, account, guardianContract, accountLock);
    }
}
