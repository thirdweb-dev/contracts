// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWRegistry.sol";

// Helpers
import "contracts/interfaces/IThirdwebModule.sol";

interface ITWRegistryData {
    event ModuleAdded(address indexed moduleAddress, address indexed deployer);
    event ModuleDeleted(address indexed moduleAddress, address indexed deployer);
}

contract TWRegistryTest is ITWRegistryData, BaseTest {
    // Target contract
    TWRegistry internal twRegistry;

    // Actors
    address internal factory = address(0x1);
    address internal deployer = address(0x2);

    // Test params
    address internal trustedForwarder = address(0x3);
    address internal mockModuleAddress = address(0x5);

    //  =====   Set up  =====

    function setUp() public {
        vm.prank(factory);
        twRegistry = new TWRegistry(trustedForwarder);
    }

    //  =====   Initial state   =====

    /**
     *  @dev Tests the relevant initial state of the contract.
     *
     *  - Should return no modules registered for any address
     *  - Should assign admin and factory roles to contract deployer
     */

    function test_initialState(address _deployer) public {
        address[] memory modules = twRegistry.getAllModules(_deployer);
        assertEq(modules.length, 0);

        assertTrue(twRegistry.hasRole(twRegistry.DEFAULT_ADMIN_ROLE(), factory));
        assertTrue(twRegistry.hasRole(twRegistry.OPERATOR_ROLE(), factory));
    }

    //  =====   Functionality tests   =====

    /// @dev Test `addModule`

    function test_addModule() public {
        vm.prank(factory);
        twRegistry.addModule(mockModuleAddress, deployer);

        address[] memory modules = twRegistry.getAllModules(deployer);
        assertEq(modules.length, 1);
        assertEq(modules[0], mockModuleAddress);
    }

    function test_addModule_revert_notOperator() public {
        vm.expectRevert("not operator.");

        vm.prank(deployer);
        twRegistry.addModule(mockModuleAddress, deployer);
    }

    function test_addModule_emit_ModuleAdded() public {
        vm.expectEmit(true, true, false, true);
        emit ModuleAdded(mockModuleAddress, deployer);

        vm.prank(factory);
        twRegistry.addModule(mockModuleAddress, deployer);
    }

    /// @dev Test `removeModule`

    function _setup_removeModule() internal {
        vm.prank(factory);
        twRegistry.addModule(mockModuleAddress, deployer);
    }

    function test_removeModule() public {
        _setup_removeModule();

        vm.prank(deployer);
        twRegistry.removeModule(mockModuleAddress, deployer);

        address[] memory modules = twRegistry.getAllModules(deployer);
        assertEq(modules.length, 0);
    }

    function test_removeModule_revert_invalidCaller() public {
        _setup_removeModule();

        address invalidCaller = address(0x123);
        assertTrue(invalidCaller != factory || invalidCaller != deployer);

        vm.expectRevert("not operator or deployer.");

        vm.prank(invalidCaller);
        twRegistry.removeModule(mockModuleAddress, deployer);
    }

    function test_removeModule_revert_noModulesToRemove() public {
        address[] memory modules = twRegistry.getAllModules(deployer);
        assertEq(modules.length, 0);

        vm.expectRevert("failed to remove module.");

        vm.prank(deployer);
        twRegistry.removeModule(mockModuleAddress, deployer);
    }

    function test_removeModule_emit_ModuleDeleted() public {
        _setup_removeModule();

        vm.expectEmit(true, true, false, true);
        emit ModuleDeleted(mockModuleAddress, deployer);

        vm.prank(deployer);
        twRegistry.removeModule(mockModuleAddress, deployer);
    }
}
