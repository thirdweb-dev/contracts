// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../interface/IExecutor.sol";
import "../interface/IVault.sol";

import "../../../../lib/CurrencyTransferLib.sol";
import "../../../../eip/interface/IERC20.sol";

import "../../../../extension/PermissionsEnumerable.sol";
import "../../../../extension/Initializable.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract TargetCheckout is Initializable, PermissionsEnumerable, IExecutor {
    function initialize(address _defaultAdmin) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    // =================================================
    // =============== Withdraw ========================
    // =================================================

    function withdraw(address _token, uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);
    }

    // =================================================
    // =============== Executor functions ==============
    // =================================================

    function execute(UserOp calldata op) external {
        require(_canExecute(), "Not authorized");

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
        // require(_canExecute(), "Not authorized");
        // TODO: Perform swap and execute here
    }

    // TODO: Re-evaluate utility of this function
    function _canExecute() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
