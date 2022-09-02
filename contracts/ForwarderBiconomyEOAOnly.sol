// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./biconomy-forwarder/BiconomyForwarderEOAOnly.sol";

contract ForwarderBiconomyEOAOnly is BiconomyForwarderEOAOnly {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) BiconomyForwarderEOAOnly(_owner) {}
}
