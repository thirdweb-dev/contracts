// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TWUpgradeable is Initializable, UUPSUpgradeable {
    function __TWUpgradeable_init() internal onlyInitializing {
        __UUPSUpgradeable_init();

        __TWUpgradeable_init_unchained();
    }

    function __TWUpgradeable_init_unchained() internal onlyInitializing {}

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}