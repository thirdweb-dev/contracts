// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Interface
import { ITWMultichainRegistry } from "contracts/interfaces/ITWMultichainRegistry.sol";
import { TWMultichainRegistry } from "contracts/registry/TWMultichainRegistry.sol";

// Plugins
import "contracts/plugin/PluginRegistry.sol";
import { MultichainRegistryCore } from "contracts/registry/plugin/MultichainRegistryCore.sol";
import "contracts/extension/Permissions.sol";
import "contracts/openzeppelin-presets/metatx/ERC2771Context.sol";

// Test imports
import { BaseTest } from "./utils/BaseTest.sol";
import "./mocks/MockThirdwebContract.sol";
import "contracts/TWProxy.sol";
import "contracts/lib/TWStrings.sol";

interface ITWMultichainRegistryData {
    event Added(address indexed deployer, address indexed deployment, uint256 indexed chainId, string metadataUri);
    event Deleted(address indexed deployer, address indexed deployment, uint256 indexed chainId);
}

contract MetaTx is ERC2771Context {
    constructor(address[] memory trustedForwarder) ERC2771Context(trustedForwarder) {}
}

contract TWMultichainRegistryTest is IPlugin, ITWMultichainRegistryData, BaseTest {
    // Target contract
    MultichainRegistryCore internal multichainRegistry;

    // Test params
    address internal operator;
    address internal pluginAdmin;
    address internal contractDeployer;

    uint256[] internal chainIds;
    address[] internal deploymentAddresses;

    mapping(uint256 => address[]) private deploymentsOnChain;
    mapping(address => string) private metadataURI;

    uint256 internal numberOfChains = 10;
    uint256 internal deploymentsPerChain = 1000;

    uint256 contractsToAdd = 1000;

    //  =====   Set up  =====

    function setUp() public override {
        super.setUp();

        operator = getActor(100);
        pluginAdmin = getActor(101);
        contractDeployer = getActor(102);

        // Populate test data.
        for (uint256 i = 0; i < numberOfChains; i += 1) {
            chainIds.push(i);

            vm.startPrank(contractDeployer);

            for (uint256 j = 0; j < deploymentsPerChain; j += 1) {
                address depl = address(new MockThirdwebContract());
                metadataURI[depl] = TWStrings.toString(i * j);
                deploymentsOnChain[i].push(depl);
            }

            vm.stopPrank();
        }

        // Deploy plugins

        // Plugin: ERC2771Context
        address erc2771Context = address(new MetaTx(forwarders()));

        Plugin memory plugin_erc2771Context;
        plugin_erc2771Context.metadata = PluginMetadata({
            name: "ERC2771Context",
            metadataURI: "ipfs://ERC2771Context",
            implementation: erc2771Context
        });

        plugin_erc2771Context.functions = new PluginFunction[](1);
        plugin_erc2771Context.functions[0] = PluginFunction(
            ERC2771Context.isTrustedForwarder.selector,
            "isTrustedForwarder(address)"
        );

        // Plugin: Permissions
        address permissions = address(new Permissions());

        Plugin memory plugin_permissions;
        plugin_permissions.metadata = PluginMetadata({
            name: "Permissions",
            metadataURI: "ipfs://Permissions",
            implementation: permissions
        });

        plugin_permissions.functions = new PluginFunction[](1);
        plugin_permissions.functions[0] = PluginFunction(Permissions.hasRole.selector, "hasRole(bytes32,address)");

        // Plugin: MultichainRegistryCore
        address multichainRegistryCore = address(new MultichainRegistryCore());

        Plugin memory plugin_multichainRegistryCore;
        plugin_multichainRegistryCore.metadata = PluginMetadata({
            name: "MultichainRegistryCore",
            metadataURI: "ipfs://MultichainRegistryCore",
            implementation: multichainRegistryCore
        });

        plugin_multichainRegistryCore.functions = new PluginFunction[](5);
        plugin_multichainRegistryCore.functions[0] = PluginFunction(
            MultichainRegistryCore.add.selector,
            "add(address,address,uint256,string)"
        );
        plugin_multichainRegistryCore.functions[1] = PluginFunction(
            MultichainRegistryCore.remove.selector,
            "remove(address,address,uint256)"
        );
        plugin_multichainRegistryCore.functions[2] = PluginFunction(
            MultichainRegistryCore.getAll.selector,
            "getAll(address)"
        );
        plugin_multichainRegistryCore.functions[3] = PluginFunction(
            MultichainRegistryCore.count.selector,
            "count(address)"
        );
        plugin_multichainRegistryCore.functions[4] = PluginFunction(
            MultichainRegistryCore.getMetadataUri.selector,
            "getMetadataUri(uint256,address)"
        );

        // Deploy plugin registry
        vm.startPrank(pluginAdmin);
        PluginRegistry pluginRegistry = new PluginRegistry(pluginAdmin);

        pluginRegistry.addPlugin(plugin_erc2771Context);
        pluginRegistry.addPlugin(plugin_permissions);
        pluginRegistry.addPlugin(plugin_multichainRegistryCore);

        vm.stopPrank();

        string[] memory pluginNames = new string[](3);
        pluginNames[0] = plugin_erc2771Context.metadata.name;
        pluginNames[1] = plugin_permissions.metadata.name;
        pluginNames[2] = plugin_multichainRegistryCore.metadata.name;

        address payable registryImpl = payable(address(new TWMultichainRegistry(address(pluginRegistry), pluginNames)));

        multichainRegistry = MultichainRegistryCore(
            payable(
                address(
                    new TWProxy(
                        registryImpl,
                        abi.encodeWithSelector(TWMultichainRegistry.initialize.selector, operator)
                    )
                )
            )
        );
    }

    function test_revert_reInitializingContract() external {
        vm.expectRevert("Initializable: contract is already initialized");
        TWMultichainRegistry(payable(address(multichainRegistry))).initialize(address(0x123));
    }

    /// ========== Test `add` ==========

    function test_state_add() external {
        vm.startPrank(operator);

        // Add all deployments.
        for (uint256 i = 0; i < numberOfChains; i += 1) {
            uint256 chainId = chainIds[i];

            for (uint256 j = 0; j < deploymentsPerChain; j += 1) {
                address deployment = deploymentsOnChain[chainId][j];

                vm.expectEmit(true, true, true, false);
                emit Added(contractDeployer, deployment, chainId, metadataURI[deployment]);

                multichainRegistry.add(contractDeployer, deployment, chainId, metadataURI[deployment]);
            }
        }

        vm.stopPrank();

        // Check contract count.
        uint256 expectedCount = numberOfChains * deploymentsPerChain;
        assertEq(multichainRegistry.count(contractDeployer), expectedCount);

        // Check all deployments.
        ITWMultichainRegistry.Deployment[] memory deployments = multichainRegistry.getAll(contractDeployer);
        assertEq(deployments.length, expectedCount);

        uint256 chainId = 0;
        uint256 deploymentIndex = 0;

        for (uint256 i = 0; i < expectedCount; i += 1) {
            if (i > 0 && i % deploymentsPerChain == 0) {
                chainId += 1;
                deploymentIndex = 0;
            }

            assertEq(deployments[i].chainId, chainId);

            address deployment = deploymentsOnChain[chainId][deploymentIndex];
            assertEq(deployments[i].deploymentAddress, deployment);

            assertEq(deployments[i].metadataURI, metadataURI[deployment]);
            assertEq(multichainRegistry.getMetadataUri(chainId, deployment), metadataURI[deployment]);

            deploymentIndex += 1;
        }
    }

    function test_revert_add_notOperatorOrDeployer() external {
        uint256 chainId = 0;
        address deployment = deploymentsOnChain[chainId][0];

        vm.expectRevert("Multichain Registry: not operator or deployer.");
        multichainRegistry.add(contractDeployer, deployment, chainId, metadataURI[deployment]);
    }

    function test_revert_add_alreadyAdded() external {
        uint256 chainId = 0;
        address deployment = deploymentsOnChain[chainId][0];

        vm.prank(operator);
        multichainRegistry.add(contractDeployer, deployment, chainId, metadataURI[deployment]);

        vm.expectRevert("Multichain Registry: contract already added.");
        vm.prank(operator);
        multichainRegistry.add(contractDeployer, deployment, chainId, metadataURI[deployment]);
    }

    /// ========== Test `remove` ==========

    function setUp_remove() public {
        vm.startPrank(operator);

        // Add all deployments.
        for (uint256 i = 0; i < numberOfChains; i += 1) {
            uint256 chainId = chainIds[i];

            for (uint256 j = 0; j < deploymentsPerChain; j += 1) {
                address deployment = deploymentsOnChain[chainId][j];

                vm.expectEmit(true, true, true, false);
                emit Added(contractDeployer, deployment, chainId, metadataURI[deployment]);

                multichainRegistry.add(contractDeployer, deployment, chainId, metadataURI[deployment]);
            }
        }

        vm.stopPrank();
    }

    function test_state_remove() external {
        setUp_remove();

        vm.startPrank(operator);

        // Add all deployments.
        for (uint256 i = 0; i < numberOfChains; i += 1) {
            uint256 chainId = chainIds[i];

            for (uint256 j = 0; j < deploymentsPerChain; j += 1) {
                address deployment = deploymentsOnChain[chainId][j];

                vm.expectEmit(true, true, true, false);
                emit Deleted(contractDeployer, deployment, chainId);

                multichainRegistry.remove(contractDeployer, deployment, chainId);
            }
        }

        vm.stopPrank();

        // Check contract count.
        uint256 expectedCount = 0;
        assertEq(multichainRegistry.count(contractDeployer), expectedCount);

        // Check all deployments.
        ITWMultichainRegistry.Deployment[] memory deployments = multichainRegistry.getAll(contractDeployer);
        assertEq(deployments.length, expectedCount);
    }

    function test_revert_remove_notOperatorOrDeployer() external {
        setUp_remove();

        uint256 chainId = 0;
        address deployment = deploymentsOnChain[chainId][0];

        vm.expectRevert("Multichain Registry: not operator or deployer.");
        multichainRegistry.remove(contractDeployer, deployment, chainId);
    }

    function test_revert_remove_nonExistentDeployment() external {
        setUp_remove();

        uint256 chainId = 0;
        address deployment = deploymentsOnChain[chainId][0];

        vm.prank(operator);
        multichainRegistry.remove(contractDeployer, deployment, chainId);

        vm.expectRevert("Multichain Registry: contract already removed.");
        vm.prank(operator);
        multichainRegistry.remove(contractDeployer, deployment, chainId);
    }
}
