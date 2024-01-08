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

import { IPRBProxyPlugin } from "./IPRBProxyPlugin.sol";

import { TargetCheckout } from "./TargetCheckout.sol";

contract PluginCheckout is IPRBProxyPlugin, TargetCheckout {
    function getMethods() external pure override returns (bytes4[] memory) {
        bytes4[] memory methods = new bytes4[](11);
        methods[0] = this.withdraw.selector;
        methods[1] = this.hasRole.selector;
        methods[2] = this.getRoleAdmin.selector;
        methods[3] = this.grantRole.selector;
        methods[4] = this.revokeRole.selector;
        methods[5] = this.renounceRole.selector;
        methods[6] = this.DEFAULT_ADMIN_ROLE.selector;
        methods[7] = this.getRoleMember.selector;
        methods[8] = this.getRoleMemberCount.selector;
        methods[9] = this.execute.selector;
        methods[10] = this.swapAndExecute.selector;
        return methods;
    }
}
