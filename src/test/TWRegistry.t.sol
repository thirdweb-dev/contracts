// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./utils/BaseTest.sol";
import "contracts/TWRegistry.sol";

contract TWRegistryTest is BaseTest {
    TWRegistry registry;
    address registryDeployer = address(0x4440);
    address proxyFactory = address(0x4441);
    address trustedForwarder = address(0x4442);

    function setUp() public {
        vm.startPrank(registryDeployer);
        registry = new TWRegistry(proxyFactory, trustedForwarder);
    }

    function test_RegistryDeployerHasAdminRole() public {
        assert(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), registryDeployer));
    }

    function test_FactoryHasFactoryRole() public {
        assert(registry.hasRole(registry.FACTORY_ROLE(), proxyFactory));
    }

    function test_AddModule_ProxyFactoryForAnyDeployer() public {
        bytes32 moduleType = bytes32("42");
        vm.startPrank(proxyFactory);
        registry.addDeployment(address(0x2), address(0x3));
        assert(registry.getAllModules(address(0x3)).length == 1);
    }

    function test_AddModule_SenderForSelf() public {
        bytes32 moduleType = bytes32("42");
        address sender = address(0x321);
        vm.startPrank(sender);
        registry.addDeployment(address(0x3), sender);
        assert(registry.getAllModules(sender).length == 1);
    }

    function test_AddModule_SenderForOtherDeployer_Revert() public {
        vm.expectRevert("not factory");
        registry.addDeployment(address(0x2), address(0x4));
    }
}
