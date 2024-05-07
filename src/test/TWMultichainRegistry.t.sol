// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/infra/interface/ITWMultichainRegistry.sol";
import { TWMultichainRegistry } from "contracts/infra/TWMultichainRegistry.sol";
import "./mocks/MockThirdwebContract.sol";
import "contracts/extension/interface/plugin/IPluginMap.sol";

interface ITWMultichainRegistryData {
    event Added(address indexed deployer, address indexed moduleAddress, uint256 indexed chainid, string metadataUri);
    event Deleted(address indexed deployer, address indexed moduleAddress, uint256 indexed chainid);
}

contract TWMultichainRegistryTest is ITWMultichainRegistryData, BaseTest {
    // Target contract
    TWMultichainRegistry internal _registry;

    // Test params
    address internal factoryAdmin_;
    address internal factory_;

    uint256[] internal chainIds;
    address[] internal deploymentAddresses;
    address internal deployer_;

    uint256 total = 1000;

    //  =====   Set up  =====

    function setUp() public override {
        super.setUp();

        deployer_ = getActor(100);
        factory_ = getActor(101);
        factoryAdmin_ = getActor(102);

        for (uint256 i = 0; i < total; i += 1) {
            chainIds.push(i);
            vm.prank(deployer_);
            address depl = address(new MockThirdwebContract());
            deploymentAddresses.push(depl);
        }

        vm.startPrank(factoryAdmin_);
        _registry = new TWMultichainRegistry(address(0));

        _registry.grantRole(keccak256("OPERATOR_ROLE"), factory_);

        vm.stopPrank();
    }

    function test_interfaceId() public pure {
        console2.logBytes4(type(IPluginMap).interfaceId);
    }

    //  =====   Functionality tests   =====

    /// @dev Test `add`

    function test_addFromFactory() public {
        vm.startPrank(factory_);
        for (uint256 i = 0; i < total; i += 1) {
            _registry.add(deployer_, deploymentAddresses[i], chainIds[i], "");
        }
        vm.stopPrank();

        ITWMultichainRegistry.Deployment[] memory modules = _registry.getAll(deployer_);

        assertEq(modules.length, total);
        assertEq(_registry.count(deployer_), total);

        for (uint256 i = 0; i < total; i += 1) {
            assertEq(modules[i].deploymentAddress, deploymentAddresses[i]);
            assertEq(modules[i].chainId, chainIds[i]);
        }

        vm.prank(factory_);
        _registry.add(deployer_, address(0x43), 111, "");

        modules = _registry.getAll(deployer_);
        assertEq(modules.length, total + 1);
        assertEq(_registry.count(deployer_), total + 1);
    }

    function test_addFromSelf() public {
        vm.startPrank(deployer_);
        for (uint256 i = 0; i < total; i += 1) {
            _registry.add(deployer_, deploymentAddresses[i], chainIds[i], "");
        }
        vm.stopPrank();

        ITWMultichainRegistry.Deployment[] memory modules = _registry.getAll(deployer_);

        assertEq(modules.length, total);
        assertEq(_registry.count(deployer_), total);

        for (uint256 i = 0; i < total; i += 1) {
            assertEq(modules[i].deploymentAddress, deploymentAddresses[i]);
            assertEq(modules[i].chainId, chainIds[i]);
        }

        vm.prank(factory_);
        _registry.add(deployer_, address(0x43), 111, "");

        modules = _registry.getAll(deployer_);
        assertEq(modules.length, total + 1);
        assertEq(_registry.count(deployer_), total + 1);
    }

    function test_add_emit_Added() public {
        vm.expectEmit(true, true, true, true);
        emit Added(deployer_, deploymentAddresses[0], chainIds[0], "uri");

        vm.prank(factory_);
        _registry.add(deployer_, deploymentAddresses[0], chainIds[0], "uri");

        string memory uri = _registry.getMetadataUri(chainIds[0], deploymentAddresses[0]);
        assertEq(uri, "uri");
    }

    // Test `remove`

    function setUp_remove() public {
        vm.startPrank(factory_);
        for (uint256 i = 0; i < total; i += 1) {
            _registry.add(deployer_, deploymentAddresses[i], chainIds[i], "");
        }
        vm.stopPrank();
    }

    //  =====   Functionality tests   =====
    function test_removeFromFactory() public {
        setUp_remove();
        vm.prank(factory_);
        _registry.remove(deployer_, deploymentAddresses[0], chainIds[0]);

        ITWMultichainRegistry.Deployment[] memory modules = _registry.getAll(deployer_);
        assertEq(modules.length, total - 1);

        for (uint256 i = 0; i < total - 1; i += 1) {
            assertEq(modules[i].deploymentAddress, deploymentAddresses[i + 1]);
            assertEq(modules[i].chainId, chainIds[i + 1]);
        }
    }

    function test_removeFromSelf() public {
        setUp_remove();
        vm.prank(factory_);
        _registry.remove(deployer_, deploymentAddresses[0], chainIds[0]);

        ITWMultichainRegistry.Deployment[] memory modules = _registry.getAll(deployer_);
        assertEq(modules.length, total - 1);
    }

    function test_remove_revert_invalidCaller() public {
        setUp_remove();
        address invalidCaller = address(0x123);
        assertTrue(invalidCaller != factory_ || invalidCaller != deployer_);

        vm.expectRevert("not operator or deployer.");

        vm.prank(invalidCaller);
        _registry.remove(deployer_, deploymentAddresses[0], chainIds[0]);
    }

    function test_remove_revert_noModulesToRemove() public {
        setUp_remove();
        address actor = getActor(1);
        ITWMultichainRegistry.Deployment[] memory modules = _registry.getAll(actor);
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
