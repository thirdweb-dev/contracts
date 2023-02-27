// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../ERC2771Context.sol";

contract MetaTx is ERC2771Context {
    constructor(address[] memory trustedForwarder) ERC2771Context(trustedForwarder) {}
}
