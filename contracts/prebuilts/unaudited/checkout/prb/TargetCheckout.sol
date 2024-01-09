// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../interface/IExecutor.sol";
import "../interface/IVault.sol";

import "../../../../lib/CurrencyTransferLib.sol";
import "../../../../eip/interface/IERC20.sol";

import { IPRBProxy } from "./IPRBProxy.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract TargetCheckout is IExecutor {
    // =================================================
    // =============== Withdraw ========================
    // =================================================

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == IPRBProxy(address(this)).owner(), "Not authorized");

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);
    }

    // =================================================
    // =============== Executor functions ==============
    // =================================================

    function execute(UserOp calldata op) external {
        bool success;
        if (op.currency == CurrencyTransferLib.NATIVE_TOKEN) {
            (success, ) = op.target.call{ value: op.valueToSend }(op.data);
        } else {
            if (op.valueToSend != 0 && op.approvalRequired) {
                IERC20(op.currency).approve(op.target, op.valueToSend);
            }

            (success, ) = op.target.call(op.data);
        }

        require(success, "Execution failed");
    }

    function swapAndExecute(UserOp calldata op, SwapOp calldata swap) external {
        // TODO: Perform swap and execute here
    }
}
