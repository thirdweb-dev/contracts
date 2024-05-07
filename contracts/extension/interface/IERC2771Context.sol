// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC2771Context {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}
