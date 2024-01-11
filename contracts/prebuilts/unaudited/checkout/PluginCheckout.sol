// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import { IPRBProxyPlugin } from "@prb/proxy/src/interfaces/IPRBProxyPlugin.sol";

import "./TargetCheckout.sol";

contract PluginCheckout is IPRBProxyPlugin, TargetCheckout {
    function getMethods() external pure override returns (bytes4[] memory) {
        bytes4[] memory methods = new bytes4[](4);
        methods[0] = this.withdraw.selector;
        methods[1] = this.execute.selector;
        methods[2] = this.swapAndExecute.selector;
        methods[3] = this.approveSwapRouter.selector;
        return methods;
    }
}
