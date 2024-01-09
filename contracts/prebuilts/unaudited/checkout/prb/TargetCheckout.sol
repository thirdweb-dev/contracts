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
    mapping(address => bool) public isApprovedRouter;

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == IPRBProxy(address(this)).owner(), "Not authorized");

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);
    }

    function approveSwapRouter(address _swapRouter, bool _toApprove) external {
        require(msg.sender == IPRBProxy(address(this)).owner(), "Not authorized");
        require(_swapRouter != address(0), "Zero address");

        isApprovedRouter[_swapRouter] = _toApprove;
    }

    function execute(UserOp calldata op) external {
        address owner = IPRBProxy(address(this)).owner();
        if (owner != msg.sender) {
            bool permission = IPRBProxy(address(this)).registry().getPermissionByOwner({
                owner: owner,
                envoy: msg.sender,
                target: op.target
            });
            require(permission, "Not authorized");
        }
        _execute(op);
    }

    function swapAndExecute(UserOp calldata op, SwapOp calldata swapOp) external {
        require(isApprovedRouter[swapOp.router], "Invalid router address");

        address owner = IPRBProxy(address(this)).owner();
        if (owner != msg.sender) {
            bool permission = IPRBProxy(address(this)).registry().getPermissionByOwner({
                owner: owner,
                envoy: msg.sender,
                target: op.target
            });
            require(permission, "Not authorized");
        }

        _swap(swapOp);
        _execute(op);
    }

    // =================================================
    // =============== Internal functions ==============
    // =================================================

    function _execute(UserOp calldata op) internal {
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

    function _swap(SwapOp memory _swapOp) internal {
        address _tokenIn = _swapOp.tokenIn;
        address _router = _swapOp.router;

        // get quote for amountIn
        (, bytes memory quoteData) = _router.staticcall(_swapOp.quoteCalldata);
        uint256 amountIn;
        uint256 offset = _swapOp.amountInOffset;

        assembly {
            amountIn := mload(add(add(quoteData, 32), offset))
        }

        // perform swap
        bool success;
        if (_tokenIn == CurrencyTransferLib.NATIVE_TOKEN) {
            (success, ) = _router.call{ value: amountIn }(_swapOp.swapCalldata);
        } else {
            IERC20(_tokenIn).approve(_swapOp.router, amountIn);
            (success, ) = _router.call(_swapOp.swapCalldata);
        }

        require(success, "Swap failed");
    }
}
