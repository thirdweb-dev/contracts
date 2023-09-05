// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../interface/IOperatorFilterRegistry.sol";
import { OperatorFilterToggleStorage } from "../OperatorFilterToggle.sol";

contract DefaultOperatorFiltererInit {
    event OperatorRestriction(bool restriction);

    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function _setupOperatorFilterer() internal {
        __DefaultOperatorFilterer_init();
    }

    function __DefaultOperatorFilterer_init() private {
        __OperatorFilterer_init(DEFAULT_SUBSCRIPTION, true);

        OperatorFilterToggleStorage.Data storage data = OperatorFilterToggleStorage.data();
        data.operatorRestriction = true;

        emit OperatorRestriction(true);
    }

    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe) private {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    }
}
