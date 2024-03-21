// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./ISwap.sol";

interface IVault is ISwap {
    /// @dev Emitted when contract admin withdraws tokens.
    event TokensWithdrawn(address _token, uint256 _amount);

    /// @dev Emitted when executor contract withdraws tokens.
    event TokensTransferredToExecutor(address indexed _executor, address _token, uint256 _amount);

    function withdraw(address _token, uint256 _amount) external;

    function transferTokensToExecutor(address _token, uint256 _amount) external;

    function swapAndTransferTokensToExecutor(address _token, uint256 _amount, SwapOp memory _swapOp) external;

    function setExecutor(address _executor) external;

    function approveSwapRouter(address _swapRouter, bool _toApprove) external;

    function canAuthorizeVaultToExecutor(address _expectedAdmin) external view returns (bool);
}
