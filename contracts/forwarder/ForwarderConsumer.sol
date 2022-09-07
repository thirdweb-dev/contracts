// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract ForwarderConsumer is ERC2771Context {
    address public caller;

    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {}

    function setCaller() external {
        caller = _msgSender();
    }
}
