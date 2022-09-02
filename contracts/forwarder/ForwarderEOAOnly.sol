// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../openzeppelin-presets/metatx/MinimalForwarderEOAOnly.sol";

/*
 * @dev Minimal forwarder for GSNv2
 */
contract ForwarderEOAOnly is MinimalForwarderEOAOnly {
    // solhint-disable-next-line no-empty-blocks
    constructor() MinimalForwarderEOAOnly() {}
}
