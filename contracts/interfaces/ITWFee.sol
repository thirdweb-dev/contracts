// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ITWFee {
    function getFeeInfo(address _proxy, uint256 _type) external view returns (address recipient, uint256 bps);
}
