// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IEntrypoint {
    function getFunctionMap() external view returns (address map);
}
