// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

/*
 * @dev Minimal forwarder for GSNv2
 */
contract Forwarder is MinimalForwarder {
    // solhint-disable-next-line no-empty-blocks
    constructor() MinimalForwarder() {}
}
