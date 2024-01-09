// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IPluginCheckout {
    /**
     *  @notice Details of the transaction to execute on target contract.
     *
     *  @param target            Address to send the transaction to
     *
     *  @param currency          Represents both native token and erc20 token
     *
     *  @param approvalRequired  If need to approve erc20 to the target contract
     *
     *  @param valueToSend       Transaction value to send - both native and erc20
     *
     *  @param data              Transaction calldata
     */
    struct UserOp {
        address target;
        address currency;
        bool approvalRequired;
        uint256 valueToSend;
        bytes data;
    }

    struct SwapOp {
        address router;
        address tokenOut;
        address tokenIn;
        uint256 amountIn;
        uint256 amountInOffset;
        bytes swapCalldata;
        bytes quoteCalldata;
    }

    function execute(UserOp calldata op) external;

    function swapAndExecute(UserOp calldata op, SwapOp memory swapOp) external;
}
