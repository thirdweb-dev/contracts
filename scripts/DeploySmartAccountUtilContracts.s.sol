// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { Script } from "forge-std/Script.sol";
import { EntryPoint } from "contracts/prebuilts/account/utils/EntryPoint.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Account } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { AccountRecovery } from "contracts/prebuilts/account/utils/AccountRecovery.sol";

import { CrossChainTokenTransfer } from "contracts/prebuilts/account/utils/CrossChainTokenTransfer.sol";
import { CrossChainTokenTransferMaster } from "contracts/prebuilts/account/utils/CrossChainTokenTransferMaster.sol";

contract DeploySmartAccountUtilContracts is Script {
    address public admin = makeAddr("admin");
    address smartWalletAccount;

    // This deploy script should only be used for testing purposes as it deploys a smart account as well.
    function run() external returns (address, AccountFactory, Guardian, AccountLock, AccountGuardian, AccountRecovery) {
        EntryPoint _entryPoint;
        AccountFactory accountFactory;

        if (block.chainid == 11155111) {
            // Sepolia

            vm.startBroadcast(vm.envUint("SEPOLIA_PRIVATE_KEY"));
            _entryPoint = new EntryPoint();
            accountFactory = new AccountFactory(
                _entryPoint,
                0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, // address(_ccipRouter)
                0x779877A7B0D9E8603169DdbD7836e478b4624789 // address(_LinkToken)
            );

            ///@dev accountGuardian is deployed when new smart account is created using the AccountFactory::createAccount(...)
            smartWalletAccount = accountFactory.createAccount(admin, abi.encode("shiven@gmail.com"));
            vm.stopBroadcast();
        } else {
            // Anvil
            /// @dev _router & _link will be zero addresses as we cannot test CCIP on Anvil due to it's infrastructure.

            vm.startBroadcast();
            _entryPoint = new EntryPoint();
            accountFactory = new AccountFactory(_entryPoint, address(0), address(0));
            smartWalletAccount = accountFactory.createAccount(admin, abi.encode("shiven@gmail.com"));
            vm.stopBroadcast();
        }

        Guardian guardianContract = accountFactory.guardian();
        AccountLock accountLock = accountFactory.accountLock();

        AccountGuardian accountGuardian = AccountGuardian(guardianContract.getAccountGuardian(smartWalletAccount));

        AccountRecovery accountRecovery = AccountRecovery(guardianContract.getAccountRecovery(smartWalletAccount));

        CrossChainTokenTransfer ccTokenTranferContract = accountFactory.crossChainTokenTransfer();

        CrossChainTokenTransferMaster ccTokenTranferContractMaster = accountFactory.crossChainTokenTransferMaster();

        return (smartWalletAccount, accountFactory, guardianContract, accountLock, accountGuardian, accountRecovery);
    }
}
