// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { Script } from "forge-std/Script.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";

contract DeployGuardian is Script {
    function run() external returns (Guardian) {
        vm.broadcast();
        Guardian guardian = new Guardian();

        return guardian;
    }
}
