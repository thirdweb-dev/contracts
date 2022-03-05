// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IThirdwebForwarder {
    function isTrustedForwarder(address forwarder) external view returns (bool);

    function setTrustedForwarder(address forwarder) external;
}
