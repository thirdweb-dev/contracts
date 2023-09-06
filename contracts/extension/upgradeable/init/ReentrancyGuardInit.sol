// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from "../ReentrancyGuard.sol";
import "../Initializable.sol";

contract ReentrancyGuardInit is Initializable {
    uint256 private constant _NOT_ENTERED = 1;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage.Data storage data = ReentrancyGuardStorage.data();
        data._status = _NOT_ENTERED;
    }
}
