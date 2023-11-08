// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IVault {
    /// @dev Emitted when contract admin withdraws tokens.
    event TokensWithdrawn(address _token, uint256 _amount);

    /// @dev Emitted when contract admin deposits tokens.
    event TokensDeposited(address _token, uint256 _amount);

    /// @dev Emitted when executor contract withdraws tokens.
    event TokensTransferredToExecutor(address indexed _executor, address _token, uint256 _amount);

    function transferTokensToExecutor(address _token, uint256 _amount) external;

    function setExecutor(address _executor) external;

    function canAuthorizeVaultToExecutor(address _expectedAdmin) external view returns (bool);
}
