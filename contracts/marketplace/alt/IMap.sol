// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IMap {
    function getExtension(bytes calldata msgSig) external;
}
