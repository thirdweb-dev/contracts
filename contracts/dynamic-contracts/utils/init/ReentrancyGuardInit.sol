// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from "../ReentrancyGuard.sol";

contract ReentrancyGuardInit {
    uint256 private constant _NOT_ENTERED = 1;

    function __ReentrancyGuard_init() internal {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal {
        ReentrancyGuardStorage.Data storage data = ReentrancyGuardStorage.reentrancyGuardStorage();
        data._status = _NOT_ENTERED;
    }
}
