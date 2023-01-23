// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContext {
    function _msgSender() external view returns (address sender);

    function _msgData() external view returns (bytes calldata);
}
