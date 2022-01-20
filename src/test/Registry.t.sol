// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./utils/BaseTest.t.sol";
import "contracts/ThirdwebRegistry.sol";

contract RegistryTest is BaseTest {
    ThirdwebRegistry registry;
    address proxyFactory = address(0x1);

    function setUp() public {
        registry = new ThirdwebRegistry(proxyFactory);
    }

    function test_HasFactoryRole() public {
        assert(registry.hasRole(registry.FACTORY_ROLE(), proxyFactory));
    }

    function test_AddModule_ProxyFactoryForAnyDeployer() public {
        bytes32 moduleType = bytes32("42");
        vm.startPrank(proxyFactory);
        registry.updateDeployments(moduleType, address(0x2), address(0x3));
        assert(registry.getAllModulesOfType(moduleType, address(0x3)).length == 1);
    }

    function test_AddModule_SenderForSelf() public {
        bytes32 moduleType = bytes32("42");
        address sender = address(0x321);
        vm.startPrank(sender);
        registry.updateDeployments(moduleType, address(0x3), sender);
        assert(registry.getAllModulesOfType(moduleType, sender).length == 1);
    }

    function testFail_AddModule_SenderForRandomDeployer() public {
        bytes32 moduleType = bytes32("42");
        registry.updateDeployments(moduleType, address(0x2), address(0x4));
    }
}
