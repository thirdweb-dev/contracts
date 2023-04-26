// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { OperatorFiltererUpgradeable } from "./OperatorFiltererUpgradeable.sol";

abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function __DefaultOperatorFilterer_init() internal {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(DEFAULT_SUBSCRIPTION, true);
    }

    function subscribeToRegistry(address _subscription) external {
        require(_canSetOperatorRestriction(), "Not authorized to subscribe to registry.");
        _register(_subscription, true);
    }
}
