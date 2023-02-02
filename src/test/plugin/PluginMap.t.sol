// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/interface/plugin/IPlugin.sol";
import "contracts/extension/plugin/PluginMap.sol";
import "../mocks/MockERC20.sol";
import "../mocks/MockERC721.sol";
import "../mocks/MockERC1155.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract PluginMapTest is BaseTest, IPlugin {
    address private pluginMapDeployer;

    PluginMap private pluginMap;

    // Plugin[] private plugins;

    mapping(uint256 => Plugin) private plugins;

    function setUp() public override {
        super.setUp();

        pluginMapDeployer = address(0x123);

        vm.prank(pluginMapDeployer);
        pluginMap = new PluginMap();

        // Add plugin 1.

        plugins[0].metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugins[0].functions.push(PluginFunction(MockERC20.mint.selector, "mint(address,uint256)"));
        plugins[0].functions.push(PluginFunction(MockERC20.toggleTax.selector, "toggleTax()"));

        // Add plugin 2.

        plugins[1].metadata = PluginMetadata({
            name: "MockERC721",
            metadataURI: "ipfs://MockERC721",
            implementation: address(new MockERC721())
        });
        plugins[1].functions.push(PluginFunction(MockERC721.mint.selector, "mint(address,uint256)"));

        // Add plugin 3.

        plugins[2].metadata = PluginMetadata({
            name: "MockERC1155",
            metadataURI: "ipfs://MockERC1155",
            implementation: address(new MockERC1155())
        });
        plugins[2].functions.push(PluginFunction(MockERC1155.mint.selector, "mint(address,uint256,uint256)"));
    }

    function test_state_setPlugin() external {
        uint256 len = 3;

        for (uint256 i = 0; i < len; i += 1) {
            vm.prank(pluginMapDeployer);
            pluginMap.setPlugin(plugins[i]);
        }
        Plugin[] memory getAllPlugins = pluginMap.getAllPlugins();

        for (uint256 i = 0; i < len; i += 1) {
            // getAllPlugins
            assertEq(getAllPlugins[i].metadata.implementation, plugins[i].metadata.implementation);
            assertEq(getAllPlugins[i].metadata.name, plugins[i].metadata.name);
            assertEq(getAllPlugins[i].metadata.metadataURI, plugins[i].metadata.metadataURI);
            uint256 fnsLen = plugins[i].functions.length;
            assertEq(fnsLen, getAllPlugins[i].functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugins[i].functions[j].functionSelector, getAllPlugins[i].functions[j].functionSelector);
                assertEq(plugins[i].functions[j].functionSignature, getAllPlugins[i].functions[j].functionSignature);
            }

            // getPlugin
            Plugin memory plugin = pluginMap.getPlugin(plugins[i].metadata.name);
            assertEq(plugin.metadata.implementation, plugins[i].metadata.implementation);
            assertEq(plugin.metadata.name, plugins[i].metadata.name);
            assertEq(plugin.metadata.metadataURI, plugins[i].metadata.metadataURI);
            assertEq(fnsLen, plugin.functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugins[i].functions[j].functionSelector, getAllPlugins[i].functions[j].functionSelector);
                assertEq(plugins[i].functions[j].functionSignature, getAllPlugins[i].functions[j].functionSignature);
            }
        }
        for (uint256 i = 0; i < len; i += 1) {
            string memory name = plugins[i].metadata.name;
            PluginFunction[] memory functions = pluginMap.getAllFunctionsOfPlugin(name);
            uint256 fnsLen = plugins[i].functions.length;
            assertEq(fnsLen, functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugins[i].functions[j].functionSelector, functions[j].functionSelector);
                assertEq(plugins[i].functions[j].functionSignature, functions[j].functionSignature);
            }
        }
        for (uint256 i = 0; i < len; i += 1) {
            PluginMetadata memory metadata = plugins[i].metadata;
            PluginFunction[] memory functions = plugins[i].functions;
            for (uint256 j = 0; j < functions.length; j += 1) {
                PluginMetadata memory plugin = pluginMap.getPluginForFunction(functions[j].functionSelector);
                assertEq(plugin.implementation, metadata.implementation);
                assertEq(plugin.name, metadata.name);
                assertEq(plugin.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, pluginMap.getPluginImplementation(metadata.name));
        }
    }
}
