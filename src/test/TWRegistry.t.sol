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
    TWRegistry internal twRegistry;

    // Test params
    address internal mockModuleAddress = address(0x5);

    //  =====   Set up  =====

    function setUp() public override {
        vm.prank(factory);
        twRegistry = new TWRegistry(forwarder);
    }

    //  =====   Initial state   =====

    /**
     *  @dev Tests the relevant initial state of the contract.
     *
     *  - Should return no modules registered for any address
     *  - Should assign admin and factory roles to contract deployer
     */

    function test_initialState(address _deployer) public {
        address[] memory modules = twRegistry.getAll(_deployer);
        assertEq(modules.length, 0);

        assertTrue(twRegistry.hasRole(twRegistry.DEFAULT_ADMIN_ROLE(), factory));
        assertTrue(twRegistry.hasRole(twRegistry.OPERATOR_ROLE(), factory));
    }

    //  =====   Functionality tests   =====

    /// @dev Test `add`

    function test_add() public {
        vm.prank(factory);
        twRegistry.add(deployer, mockModuleAddress);

        address[] memory modules = twRegistry.getAll(deployer);
        assertEq(modules.length, 1);
        assertEq(modules[0], mockModuleAddress);
        assertEq(twRegistry.count(deployer), 1);

        vm.prank(factory);
        twRegistry.add(deployer, address(0x42));
        modules = twRegistry.getAll(deployer);
        assertEq(modules.length, 2);
        assertEq(modules[1], address(0x42));
        assertEq(twRegistry.count(deployer), 2);
    }

    function test_add_self() public {
        vm.prank(deployer);
        twRegistry.add(deployer, mockModuleAddress);
    }

    function test_add_emit_Added() public {
        vm.expectEmit(true, true, false, true);
        emit Added(deployer, mockModuleAddress);

        vm.prank(factory);
        twRegistry.add(deployer, mockModuleAddress);
    }

    /// @dev Test `remove`

    function _setup_remove() internal {
        vm.prank(factory);
        twRegistry.add(deployer, mockModuleAddress);
    }

    function test_remove() public {
        _setup_remove();

        vm.prank(deployer);
        twRegistry.remove(deployer, mockModuleAddress);

        address[] memory modules = twRegistry.getAll(deployer);
        assertEq(modules.length, 0);
    }

    function test_remove_revert_invalidCaller() public {
        _setup_remove();

        address invalidCaller = address(0x123);
        assertTrue(invalidCaller != factory || invalidCaller != deployer);

        vm.expectRevert("not operator or deployer.");

        vm.prank(invalidCaller);
        twRegistry.remove(deployer, mockModuleAddress);
    }

    function test_remove_revert_noModulesToRemove() public {
        address[] memory modules = twRegistry.getAll(deployer);
        assertEq(modules.length, 0);

        vm.expectRevert("failed to remove");

        vm.prank(deployer);
        twRegistry.remove(deployer, mockModuleAddress);
    }

    function test_remove_emit_Deleted() public {
        _setup_remove();

        vm.expectEmit(true, true, false, true);
        emit Deleted(deployer, mockModuleAddress);

        vm.prank(deployer);
        twRegistry.remove(deployer, mockModuleAddress);
    }
}
