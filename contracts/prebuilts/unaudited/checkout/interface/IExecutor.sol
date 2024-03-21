// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./ISwap.sol";

interface IExecutor is ISwap {
    /**
     *  @notice Details of the transaction to execute on target contract.
     *
     *  @param target            Address to send the transaction to
     *
     *  @param currency          Represents both native token and erc20 token
     *
     *  @param vault             Vault providing liquidity for this transaction
     *
     *  @param approvalRequired  If need to approve erc20 to the target contract
     *
     *  @param swap              If need to swap first
     *
     *  @param valueToSend       Transaction value to send - both native and erc20
     *
     *  @param data              Transaction calldata
     */
    struct UserOp {
        address target;
        address currency;
        address vault;
        bool approvalRequired;
        uint256 valueToSend;
        bytes data;
    }

    function execute(UserOp calldata op) external;

    function swapAndExecute(UserOp calldata op, SwapOp memory swapOp) external;
}
