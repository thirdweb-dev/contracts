// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ISwap {
    struct SwapOp {
        address tokenOut;
        address tokenIn;
        uint256 amountIn;
        bytes swapCalldata;
    }
}
