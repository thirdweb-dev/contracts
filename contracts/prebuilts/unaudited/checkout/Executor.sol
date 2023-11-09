// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./interface/IExecutor.sol";
import "./interface/IVault.sol";

import "../../../lib/CurrencyTransferLib.sol";
import "../../../eip/interface/IERC20.sol";

import "../../../extension/PermissionsEnumerable.sol";
import "../../../extension/Initializable.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract Executor is Initializable, PermissionsEnumerable, IExecutor {
    /// @dev Address of the Checkout entrypoint.
    address public checkout;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin) external initializer {
        checkout = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    receive() external payable {}

    function execute(UserOp calldata op) external {
        require(_canExecute(), "Not authorized");

        if (op.valueToSend != 0) {
            if (op.swap) {
                IVault(op.vault).swapAndTransferTokensToExecutor(op.currency, op.valueToSend);
            } else {
                IVault(op.vault).transferTokensToExecutor(op.currency, op.valueToSend);
            }
        }

        bool success;
        if (op.currency == CurrencyTransferLib.NATIVE_TOKEN) {
            (success, ) = op.target.call{ value: op.valueToSend }(op.data);
        } else {
            if (op.approvalRequired) {
                IERC20(op.currency).approve(op.target, op.valueToSend);
            }

            (success, ) = op.target.call(op.data);
        }

        require(success, "Execution failed");
    }

    // TODO: rethink design and interface here
    function swapAndExecute(UserOp calldata op) external {}

    function _canExecute() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
