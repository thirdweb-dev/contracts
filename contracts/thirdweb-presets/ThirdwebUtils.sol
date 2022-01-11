// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import { MulticallUpgradeable } from "../openzeppelin-presets/utils/MulticallUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ThirdwebUtils is 
    Initializable,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
    ERC2771ContextUpgradeable
{

    function __ThirdwebUtils_init(address _trustedForwarder) internal onlyInitializing {
        __ReentrancyGuard_init();
        __Multicall_init();
        __ERC2771Context_init(_trustedForwarder);
    }

    function __ThirdwebUtils_init_unchained() internal onlyInitializing {}
}