// SPDX-License-Identifier: Apache 2.0
// Credits: OpenSea
pragma solidity ^0.8.0;

import { OperatorFilterer } from "./OperatorFilterer.sol";

contract DefaultOperatorFilterer is OperatorFilterer {
    // solhint-disable-next-line
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}
