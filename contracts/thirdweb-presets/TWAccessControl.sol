// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TWAccessControl is Initializable, AccessControlEnumerableUpgradeable {
    

    function __TWAccessControl_init(address _deployer) internal onlyInitializing {
        __AccessControlEnumerable_init();

        __TWAccessControl_ini_unchained(_deployer);
    }

    function __TWAccessControl_ini_unchained(address _deployer) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
    }
}