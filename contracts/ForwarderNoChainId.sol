// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./MinimalForwarderNoChainId.sol";

/*
 * @dev Minimal forwarder for GSNv2
 */
contract ForwarderNoChainId is MinimalForwarderNoChainId {
    // solhint-disable-next-line no-empty-blocks
    constructor() MinimalForwarderNoChainId() {}
}
