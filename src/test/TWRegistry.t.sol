// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWRegistry.sol";

interface ITWRegistryData {
    event Added(address indexed deployer, address indexed moduleAddress);
    event Deleted(address indexed deployer, address indexed moduleAddress);
}

contract TWRegistryTest is ITWRegistryData, BaseTest {
    // Target contract
    TWRegistry internal _registry;

    // Test params
    address internal mockModuleAddress = address(0x42);
    address internal actor;

    //  =====   Set up  =====

    function setUp() public override {
        super.setUp();
        actor = getActor(0);
        _registry = TWRegistry(registry);
    }

    //  =====   Functionality tests   =====

    /// @dev Test `add`

    function test_addFromFactory() public {
        vm.prank(factory);
        _registry.add(actor, mockModuleAddress);

        address[] memory modules = _registry.getAll(actor);
        assertEq(modules.length, 1);
        assertEq(modules[0], mockModuleAddress);
        assertEq(_registry.count(actor), 1);

        vm.prank(factory);
        _registry.add(actor, address(0x43));

        modules = _registry.getAll(actor);
        assertEq(modules.length, 2);
        assertEq(_registry.count(actor), 2);
    }

    function test_addFromSelf() public {
        vm.prank(actor);
        _registry.add(actor, mockModuleAddress);

        address[] memory modules = _registry.getAll(actor);

        assertEq(modules.length, 1);
        assertEq(modules[0], mockModuleAddress);
        assertEq(_registry.count(actor), 1);
    }

    function test_add_emit_Added() public {
        vm.expectEmit(true, true, false, true);
        emit Added(actor, mockModuleAddress);

        vm.prank(factory);
        _registry.add(actor, mockModuleAddress);
    }

    // Test `remove`

    function setUp_remove() public {
        vm.prank(factory);
        _registry.add(actor, mockModuleAddress);
    }

    //  =====   Functionality tests   =====
    function test_removeFromFactory() public {
        setUp_remove();
        vm.prank(factory);
        _registry.remove(actor, mockModuleAddress);

        address[] memory modules = _registry.getAll(actor);
        assertEq(modules.length, 0);
    }

    function test_removeFromSelf() public {
        setUp_remove();
        vm.prank(actor);
        _registry.remove(actor, mockModuleAddress);

        address[] memory modules = _registry.getAll(actor);
        assertEq(modules.length, 0);
    }

    function test_remove_revert_invalidCaller() public {
        setUp_remove();
        address invalidCaller = address(0x123);
        assertTrue(invalidCaller != factory || invalidCaller != actor);

        vm.expectRevert("not operator or deployer.");

        vm.prank(invalidCaller);
        _registry.remove(actor, mockModuleAddress);
    }

    function test_remove_revert_noModulesToRemove() public {
        setUp_remove();
        actor = getActor(1);
        address[] memory modules = _registry.getAll(actor);
        assertEq(modules.length, 0);

        vm.expectRevert("failed to remove");

        vm.prank(actor);
        _registry.remove(actor, mockModuleAddress);
    }

    function test_remove_emit_Deleted() public {
        setUp_remove();
        vm.expectEmit(true, true, false, true);
        emit Deleted(actor, mockModuleAddress);

        vm.prank(actor);
        _registry.remove(actor, mockModuleAddress);
    }
}
