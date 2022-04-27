// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IDelayedReveal {
    function reveal(uint256 identifier, bytes calldata key) external returns (string memory revealedURI);

    function encryptDecrypt(bytes memory data, bytes calldata key) external pure returns (bytes memory result);
}
