// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ThirdwebUpgradeable is Initializable, UUPSUpgradeable {

    function __ThirdwebUpgradeable_init() internal onlyInitializing {
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}