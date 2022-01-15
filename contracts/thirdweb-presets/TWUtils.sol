// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-presets/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TWUtils is Initializable, ReentrancyGuardUpgradeable, MulticallUpgradeable, ERC2771ContextUpgradeable {
    function __TWUtils_init(address _trustedForwarder) internal onlyInitializing {
        __ReentrancyGuard_init();
        __Multicall_init();
        __ERC2771Context_init(_trustedForwarder);

        __TWUtils_init_unchained();
    }

    function __TWUtils_init_unchained() internal onlyInitializing {}
}
