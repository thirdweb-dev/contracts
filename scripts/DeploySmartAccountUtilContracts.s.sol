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
    address _router = address(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
    address _link = address(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    function run()
        external
        returns (
            AccountFactory,
            Guardian,
            AccountLock,
            AccountGuardian,
            AccountRecovery,
            CrossChainTokenTransfer,
            CrossChainTokenTransferMaster
        )
    {
        vm.startBroadcast(vm.envUint("SEPOLIA_PRIVATE_KEY"));

        EntryPoint _entryPoint = new EntryPoint();
        AccountFactory accountFactory = new AccountFactory(_entryPoint, _router, _link);
        vm.stopBroadcast();

        Guardian guardianContract = accountFactory.guardian();
        AccountLock accountLock = accountFactory.accountLock();
        CrossChainTokenTransfer ccTokenTranferContract = accountFactory.crossChainTokenTransfer();
        CrossChainTokenTransferMaster ccTokenTranferContractMaster = accountFactory.crossChainTokenTransferMaster();
        AccountGuardian accountGuardian = accountFactory.accountGuardian();
        AccountRecovery accountRecovery = accountGuardian.accountRecovery();

        return (
            accountFactory,
            guardianContract,
            accountLock,
            accountGuardian,
            accountRecovery,
            ccTokenTranferContract,
            ccTokenTranferContractMaster
        );
    }
}
