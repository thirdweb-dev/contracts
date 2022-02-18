// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/*
 * @dev Minimal forwarder for GSNv2
 */
contract Forwarder is MinimalForwarder {
    constructor() MinimalForwarder() {}
}
