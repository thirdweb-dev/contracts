// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/interfaces/ITWRegistry.sol";
import "contracts/TWRegistry.sol";
import "./mocks/MockThirdwebContract.sol";

interface ITWRegistryData {
    event Added(address indexed deployer, address indexed moduleAddress, uint256 indexed chainid);
    event Deleted(address indexed deployer, address indexed moduleAddress, uint256 indexed chainid);
}

contract TWRegistryTest is ITWRegistryData, BaseTest {
    // Target contract
    TWRegistry internal _registry;

    // Test params
    uint256[] internal chainIds;
    address[] internal deploymentAddresses;
    address internal deployer_;

    uint256 total = 1000;

    //  =====   Set up  =====

    function setUp() public override {
        super.setUp();

        deployer_ = getActor(100);

        for (uint256 i = 0; i < total; i += 1) {
            chainIds.push(i);
            vm.prank(deployer_);
            address depl = address(new MockThirdwebContract());
            deploymentAddresses.push(depl);
        }

        _registry = TWRegistry(registry);
    }

    //  =====   Functionality tests   =====

    /// @dev Test `add`

    function test_addFromFactory() public {
        vm.startPrank(factory);
        for (uint256 i = 0; i < total; i += 1) {
            _registry.add(deployer_, deploymentAddresses[i], chainIds[i]);
        }
        vm.stopPrank();

        ITWRegistry.Deployment[] memory modules = _registry.getAll(deployer_);

        assertEq(modules.length, total);
        assertEq(_registry.count(deployer_), total);

        for (uint256 i = 0; i < total; i += 1) {
            assertEq(modules[i].deploymentAddress, deploymentAddresses[i]);
            assertEq(modules[i].chainId, chainIds[i]);
        }

        vm.prank(factory);
        _registry.add(deployer_, address(0x43), 111);

        modules = _registry.getAll(deployer_);
        assertEq(modules.length, total + 1);
        assertEq(_registry.count(deployer_), total + 1);
    }

    function test_addFromSelf() public {
        vm.startPrank(deployer_);
        for (uint256 i = 0; i < total; i += 1) {
            _registry.add(deployer_, deploymentAddresses[i], chainIds[i]);
        }
        vm.stopPrank();

        ITWRegistry.Deployment[] memory modules = _registry.getAll(deployer_);

        assertEq(modules.length, total);
        assertEq(_registry.count(deployer_), total);

        for (uint256 i = 0; i < total; i += 1) {
            assertEq(modules[i].deploymentAddress, deploymentAddresses[i]);
            assertEq(modules[i].chainId, chainIds[i]);
        }

        vm.prank(factory);
        _registry.add(deployer_, address(0x43), 111);

        modules = _registry.getAll(deployer_);
        assertEq(modules.length, total + 1);
        assertEq(_registry.count(deployer_), total + 1);
    }

    function test_add_emit_Added() public {
        vm.expectEmit(true, true, true, true);
        emit Added(deployer_, deploymentAddresses[0], chainIds[0]);

        vm.prank(factory);
        _registry.add(deployer_, deploymentAddresses[0], chainIds[0]);
    }

    // Test `remove`

    function setUp_remove() public {
        vm.startPrank(factory);
        for (uint256 i = 0; i < total; i += 1) {
            _registry.add(deployer_, deploymentAddresses[i], chainIds[i]);
        }
        vm.stopPrank();
    }

    //  =====   Functionality tests   =====
    function test_removeFromFactory() public {
        setUp_remove();
        vm.prank(factory);
        _registry.remove(deployer_, deploymentAddresses[0], chainIds[0]);

        ITWRegistry.Deployment[] memory modules = _registry.getAll(deployer_);
        assertEq(modules.length, total - 1);

        for (uint256 i = 0; i < total - 1; i += 1) {
            assertEq(modules[i].deploymentAddress, deploymentAddresses[i + 1]);
            assertEq(modules[i].chainId, chainIds[i + 1]);
        }
    }

    function test_removeFromSelf() public {
        setUp_remove();
        vm.prank(factory);
        _registry.remove(deployer_, deploymentAddresses[0], chainIds[0]);

        ITWRegistry.Deployment[] memory modules = _registry.getAll(deployer_);
        assertEq(modules.length, total - 1);
    }

    function test_remove_revert_invalidCaller() public {
        setUp_remove();
        address invalidCaller = address(0x123);
        assertTrue(invalidCaller != factory || invalidCaller != deployer_);

        vm.expectRevert("not operator or deployer.");

        vm.prank(invalidCaller);
        _registry.remove(deployer_, deploymentAddresses[0], chainIds[0]);
    }

    function test_remove_revert_noModulesToRemove() public {
        setUp_remove();
        address actor = getActor(1);
        ITWRegistry.Deployment[] memory modules = _registry.getAll(actor);
        assertEq(modules.length, 0);

        vm.expectRevert("failed to remove");

        vm.prank(actor);
        _registry.remove(actor, deploymentAddresses[0], chainIds[0]);
    }

    function test_remove_revert_incorrectChainId() public {
        setUp_remove();

        vm.expectRevert("failed to remove");

        vm.prank(deployer_);
        _registry.remove(deployer_, deploymentAddresses[0], 12345);
    }

    function test_remove_emit_Deleted() public {
        setUp_remove();
        vm.expectEmit(true, true, true, true);
        emit Deleted(deployer_, deploymentAddresses[0], chainIds[0]);

        vm.prank(deployer_);
        _registry.remove(deployer_, deploymentAddresses[0], chainIds[0]);
    }
}
