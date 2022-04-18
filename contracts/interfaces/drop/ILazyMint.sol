// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ILazyMint {
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external;
}