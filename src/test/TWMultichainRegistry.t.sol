// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Interface
import { ITWMultichainRegistry } from "contracts/interfaces/ITWMultichainRegistry.sol";
import { TWMultichainRegistry } from "contracts/registry/TWMultichainRegistry.sol";

// Test imports
import "./utils/BaseTest.sol";
import "./mocks/MockThirdwebContract.sol";
import "contracts/TWProxy.sol";
import "contracts/lib/TWStrings.sol";

interface ITWMultichainRegistryData {
    event Added(address indexed deployer, address indexed deployment, uint256 indexed chainId, string metadataUri);
    event Deleted(address indexed deployer, address indexed deployment, uint256 indexed chainId);
}

contract TWMultichainRegistryTest is ITWMultichainRegistryData, BaseTest {
    // Target contract
    TWMultichainRegistry internal multichainRegistry;

    // Test params
    address internal operator;

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
        contractDeployer = getActor(101);

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

        // PluginRegistry, Plugin names: null values.
        address pluginRegistry = address(0);
        string[] memory pluginNames = new string[](0);

        address payable registryImpl = payable(
            address(new TWMultichainRegistry(forwarders(), pluginRegistry, pluginNames))
        );

        multichainRegistry = TWMultichainRegistry(
            payable(
                address(
                    new TWProxy(
                        registryImpl,
                        abi.encodeWithSelector(TWMultichainRegistry.initialize.selector, operator)
                    )
                )
            )
        );

        vm.stopPrank();
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
