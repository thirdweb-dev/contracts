// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ISwap {
    struct SwapOp {
        address router;
        address tokenOut;
        address tokenIn;
        uint256 amountIn;
        uint256 amountInOffset;
        bytes swapCalldata;
        bytes quoteCalldata;
    }
}
