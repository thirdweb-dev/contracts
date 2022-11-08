// SPDX-License-Identifier: Apache 2.0
// Credits: OpenSea
pragma solidity ^0.8.0;

import { IOperatorFilterRegistry } from "./interface/IOperatorFilterRegistry.sol";

contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant OPERATOR_FILTERER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTERER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTERER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTERER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTERER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator() virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTERER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTERER_REGISTRY.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}
