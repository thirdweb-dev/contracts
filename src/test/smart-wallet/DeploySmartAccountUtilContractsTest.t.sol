// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { Test } from "forge-std/Test.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { AccountLock } from "contracts/prebuilts/account/utils/AccountLock.sol";
import { AccountRecovery } from "contracts/prebuilts/account/utils/AccountRecovery.sol";
import { CrossChainTokenTransfer } from "contracts/prebuilts/account/utils/CrossChainTokenTransfer.sol";
import { CrossChainTokenTransferMaster } from "contracts/prebuilts/account/utils/CrossChainTokenTransferMaster.sol";
import { DeploySmartAccountUtilContracts } from "scripts/DeploySmartAccountUtilContracts.s.sol";

contract DeploySmartAccountUtilContractsTest is Test {
    AccountFactory accountFactory;
    Guardian guardianContract;
    AccountLock accountLock;
    AccountGuardian accountGuardian;
    AccountRecovery accountRecovery;
    CrossChainTokenTransfer ccTokenTransfer;
    CrossChainTokenTransferMaster ccTokenTransferMaster;

    function setUp() external {
        DeploySmartAccountUtilContracts deployer = new DeploySmartAccountUtilContracts();
        (
            accountFactory,
            guardianContract,
            accountLock,
            accountGuardian,
            accountRecovery,
            ccTokenTransfer,
            ccTokenTransferMaster
        ) = deployer.run();
    }

    function testIfSmartAccountUtilContractsDeployed() external {
        assert(
            address(accountFactory) != address(0) &&
                address(guardianContract) != address(0) &&
                address(accountLock) != address(0) &&
                address(accountGuardian) != address(0) &&
                address(accountRecovery) != address(0) &&
                address(ccTokenTransfer) != address(0) &&
                address(ccTokenTransferMaster) != address(0)
        );

        assert(guardianContract == accountFactory.guardian());
        assert(accountLock == accountFactory.accountLock());
        assert(accountGuardian == accountFactory.accountGuardian());
        assert(accountRecovery == accountGuardian.accountRecovery());
        assert(ccTokenTransfer == accountFactory.crossChainTokenTransfer());
        assert(ccTokenTransferMaster == accountFactory.crossChainTokenTransferMaster());
    }
}
