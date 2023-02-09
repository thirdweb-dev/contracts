// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/plugin/interface/IPlugin.sol";
import "contracts/plugin/PluginRegistry.sol";
import { BaseTest } from "../utils/BaseTest.sol";

import "../mocks/MockERC20.sol";
import "../mocks/MockERC721.sol";

contract ContractA {
    uint256 private a_;

    function a() external {
        a_ += 1;
    }
}

contract ContractB {
    uint256 private b_;

    function b() external {
        b_ += 1;
    }
}

contract ContractC {
    uint256 private c_;

    function c() external {
        c_ += 1;
    }

    function getC() external view returns (uint256) {
        return c_;
    }
}

contract PluginRegistryTest is BaseTest, IPlugin {
    address private registryDeployer;

    PluginRegistry private pluginRegistry;

    mapping(uint256 => Plugin) private plugins;

    function setUp() public override {
        super.setUp();

        registryDeployer = address(0x123);

        vm.prank(registryDeployer);
        pluginRegistry = new PluginRegistry(registryDeployer);

        // Add plugin 1.

        plugins[0].metadata = PluginMetadata({
            name: "ContractA",
            metadataURI: "ipfs://ContractA",
            implementation: address(new ContractA())
        });

        plugins[0].functions.push(PluginFunction(ContractA.a.selector, "a()"));

        // Add plugin 2.

        plugins[1].metadata = PluginMetadata({
            name: "ContractB",
            metadataURI: "ipfs://ContractB",
            implementation: address(new ContractB())
        });
        plugins[1].functions.push(PluginFunction(ContractB.b.selector, "b()"));

        // Add plugin 3.

        plugins[2].metadata = PluginMetadata({
            name: "ContractC",
            metadataURI: "ipfs://ContractC",
            implementation: address(new ContractC())
        });
        plugins[2].functions.push(PluginFunction(ContractC.c.selector, "c()"));
    }

    /*///////////////////////////////////////////////////////////////
                            Adding plugins
    //////////////////////////////////////////////////////////////*/

    function test_state_addPlugin() external {
        uint256 len = 3;

        for (uint256 i = 0; i < len; i += 1) {
            vm.prank(registryDeployer);
            pluginRegistry.addPlugin(plugins[i]);
        }
        Plugin[] memory getAllPlugins = pluginRegistry.getAllPlugins();

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
            Plugin memory plugin = pluginRegistry.getPlugin(plugins[i].metadata.name);
            assertEq(plugin.metadata.implementation, plugins[i].metadata.implementation);
            assertEq(plugin.metadata.name, plugins[i].metadata.name);
            assertEq(plugin.metadata.metadataURI, plugins[i].metadata.metadataURI);
            assertEq(fnsLen, plugin.functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugins[i].functions[j].functionSelector, plugin.functions[j].functionSelector);
                assertEq(plugins[i].functions[j].functionSignature, plugin.functions[j].functionSignature);
            }
        }
        for (uint256 i = 0; i < len; i += 1) {
            string memory name = plugins[i].metadata.name;
            PluginFunction[] memory functions = pluginRegistry.getAllFunctionsOfPlugin(name);
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
                PluginMetadata memory plugin = pluginRegistry.getPluginForFunction(functions[j].functionSelector);
                assertEq(plugin.implementation, metadata.implementation);
                assertEq(plugin.name, metadata.name);
                assertEq(plugin.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, pluginRegistry.getPluginImplementation(metadata.name));
        }
    }

    function test_revert_addPlugin_unauthorizedCaller() external {
        vm.expectRevert();
        vm.prank(address(0x999));
        pluginRegistry.addPlugin(plugins[0]);
    }

    function test_revert_addPluginsWithSameFunctionSelectors() external {
        // Add plugin 1.

        Plugin memory plugin1;

        plugin1.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin1.functions = new PluginFunction[](1);
        plugin1.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        // Add plugin 2.

        Plugin memory plugin2;

        plugin2.metadata = PluginMetadata({
            name: "MockERC721",
            metadataURI: "ipfs://MockERC721",
            implementation: address(new MockERC721())
        });

        plugin2.functions = new PluginFunction[](1);
        plugin2.functions[0] = PluginFunction(MockERC721.mint.selector, "mint(address,uint256)");

        vm.startPrank(registryDeployer);

        pluginRegistry.addPlugin(plugin1);

        vm.expectRevert("PluginState: plugin already exists for function.");
        pluginRegistry.addPlugin(plugin2);

        vm.stopPrank();
    }

    function test_revert_addPlugin_fnSelectorSignatureMismatch() external {
        Plugin memory plugin1;

        plugin1.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin1.functions = new PluginFunction[](1);
        plugin1.functions[0] = PluginFunction(MockERC20.mint.selector, "hello()");

        vm.prank(registryDeployer);
        vm.expectRevert("PluginState: fn selector and signature mismatch.");
        pluginRegistry.addPlugin(plugin1);
    }

    function test_revert_addPlugin_samePluginName() external {
        // Add plugin 1.

        Plugin memory plugin1;

        plugin1.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin1.functions = new PluginFunction[](1);
        plugin1.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        // Add plugin 2.

        Plugin memory plugin2;

        plugin2.metadata = PluginMetadata({
            name: "MockERC20", // same plugin name
            metadataURI: "ipfs://MockERC721",
            implementation: address(new MockERC721())
        });

        plugin2.functions = new PluginFunction[](1);
        plugin2.functions[0] = PluginFunction(MockERC721.mint.selector, "mint(address,uint256)");

        vm.startPrank(registryDeployer);

        pluginRegistry.addPlugin(plugin1);

        vm.expectRevert("PluginState: plugin already exists.");
        pluginRegistry.addPlugin(plugin2);

        vm.stopPrank();
    }

    function test_revert_addPlugin_emptyPluginImplementation() external {
        Plugin memory plugin1;

        plugin1.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(0)
        });

        plugin1.functions = new PluginFunction[](1);
        plugin1.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        vm.expectRevert("PluginState: adding plugin without implementation.");
        pluginRegistry.addPlugin(plugin1);
    }

    /*///////////////////////////////////////////////////////////////
                            Updating plugins
    //////////////////////////////////////////////////////////////*/

    function _setUp_updatePlugin() internal {
        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](1);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        pluginRegistry.addPlugin(plugin);
    }

    function test_state_updatePlugin_someNewFunctions() external {
        _setUp_updatePlugin();

        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](2);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");
        plugin.functions[1] = PluginFunction(MockERC20.toggleTax.selector, "toggleTax()");

        vm.prank(registryDeployer);
        pluginRegistry.updatePlugin(plugin);

        {
            Plugin[] memory getAllPlugins = pluginRegistry.getAllPlugins();
            assertEq(getAllPlugins.length, 1);

            // getAllPlugins
            assertEq(getAllPlugins[0].metadata.implementation, plugin.metadata.implementation);
            assertEq(getAllPlugins[0].metadata.name, plugin.metadata.name);
            assertEq(getAllPlugins[0].metadata.metadataURI, plugin.metadata.metadataURI);
            uint256 fnsLen = plugin.functions.length;

            assertEq(fnsLen, 2);
            assertEq(fnsLen, getAllPlugins[0].functions.length);

            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugin.functions[j].functionSelector, getAllPlugins[0].functions[j].functionSelector);
                assertEq(plugin.functions[j].functionSignature, getAllPlugins[0].functions[j].functionSignature);
            }

            // getPlugin
            Plugin memory getPlugin = pluginRegistry.getPlugin(plugin.metadata.name);
            assertEq(plugin.metadata.implementation, getPlugin.metadata.implementation);
            assertEq(plugin.metadata.name, getPlugin.metadata.name);
            assertEq(plugin.metadata.metadataURI, getPlugin.metadata.metadataURI);
            assertEq(fnsLen, getPlugin.functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(getPlugin.functions[j].functionSelector, plugin.functions[j].functionSelector);
                assertEq(getPlugin.functions[j].functionSignature, plugin.functions[j].functionSignature);
            }
        }
        {
            string memory name = plugin.metadata.name;
            PluginFunction[] memory functions = pluginRegistry.getAllFunctionsOfPlugin(name);
            uint256 fnsLen = plugin.functions.length;
            assertEq(fnsLen, functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugin.functions[j].functionSelector, functions[j].functionSelector);
                assertEq(plugin.functions[j].functionSignature, functions[j].functionSignature);
            }
        }
        {
            PluginMetadata memory metadata = plugin.metadata;
            PluginFunction[] memory functions = plugin.functions;
            for (uint256 j = 0; j < functions.length; j += 1) {
                PluginMetadata memory pluginForFunction = pluginRegistry.getPluginForFunction(
                    functions[j].functionSelector
                );
                assertEq(pluginForFunction.implementation, metadata.implementation);
                assertEq(pluginForFunction.name, metadata.name);
                assertEq(pluginForFunction.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, pluginRegistry.getPluginImplementation(metadata.name));
        }
    }

    function test_state_updatePlugin_allNewFunctions() external {
        _setUp_updatePlugin();

        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](1);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        pluginRegistry.updatePlugin(plugin);

        {
            Plugin[] memory getAllPlugins = pluginRegistry.getAllPlugins();
            assertEq(getAllPlugins.length, 1);

            // getAllPlugins
            assertEq(getAllPlugins[0].metadata.implementation, plugin.metadata.implementation);
            assertEq(getAllPlugins[0].metadata.name, plugin.metadata.name);
            assertEq(getAllPlugins[0].metadata.metadataURI, plugin.metadata.metadataURI);
            uint256 fnsLen = plugin.functions.length;

            assertEq(fnsLen, 1);
            assertEq(fnsLen, getAllPlugins[0].functions.length);

            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugin.functions[j].functionSelector, getAllPlugins[0].functions[j].functionSelector);
                assertEq(plugin.functions[j].functionSignature, getAllPlugins[0].functions[j].functionSignature);
            }

            // getPlugin
            Plugin memory getPlugin = pluginRegistry.getPlugin(plugin.metadata.name);
            assertEq(plugin.metadata.implementation, getPlugin.metadata.implementation);
            assertEq(plugin.metadata.name, getPlugin.metadata.name);
            assertEq(plugin.metadata.metadataURI, getPlugin.metadata.metadataURI);
            assertEq(fnsLen, getPlugin.functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(getPlugin.functions[j].functionSelector, plugin.functions[j].functionSelector);
                assertEq(getPlugin.functions[j].functionSignature, plugin.functions[j].functionSignature);
            }
        }
        {
            string memory name = plugin.metadata.name;
            PluginFunction[] memory functions = pluginRegistry.getAllFunctionsOfPlugin(name);
            uint256 fnsLen = plugin.functions.length;
            assertEq(fnsLen, functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(plugin.functions[j].functionSelector, functions[j].functionSelector);
                assertEq(plugin.functions[j].functionSignature, functions[j].functionSignature);
            }
        }
        {
            PluginMetadata memory metadata = plugin.metadata;
            PluginFunction[] memory functions = plugin.functions;
            for (uint256 j = 0; j < functions.length; j += 1) {
                PluginMetadata memory pluginForFunction = pluginRegistry.getPluginForFunction(
                    functions[j].functionSelector
                );
                assertEq(pluginForFunction.implementation, metadata.implementation);
                assertEq(pluginForFunction.name, metadata.name);
                assertEq(pluginForFunction.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, pluginRegistry.getPluginImplementation(metadata.name));
        }
    }

    function test_revert_updatePlugin_unauthorizedCaller() external {
        _setUp_updatePlugin();

        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](1);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.expectRevert();
        pluginRegistry.updatePlugin(plugin);
    }

    function test_revert_updatePlugin_pluginDoesNotExist() external {
        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](1);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.expectRevert("PluginState: plugin does not exist.");
        vm.prank(registryDeployer);
        pluginRegistry.updatePlugin(plugin);
    }

    function test_revert_updatePlugin_notUpdatingImplementation() external {
        _setUp_updatePlugin();

        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: pluginRegistry.getPluginImplementation("MockERC20")
        });

        plugin.functions = new PluginFunction[](1);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.expectRevert("PluginState: re-adding same plugin.");
        vm.prank(registryDeployer);
        pluginRegistry.updatePlugin(plugin);
    }

    function test_revert_updatePlugin_fnSelectorSignatureMismatch() external {
        _setUp_updatePlugin();

        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](1);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "hello(address,uint256)");

        vm.expectRevert("PluginState: fn selector and signature mismatch.");
        vm.prank(registryDeployer);
        pluginRegistry.updatePlugin(plugin);
    }

    /*///////////////////////////////////////////////////////////////
                            Removing plugins
    //////////////////////////////////////////////////////////////*/

    function _setUp_removePlugin() internal {
        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](2);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");
        plugin.functions[1] = PluginFunction(MockERC20.toggleTax.selector, "toggleTax()");

        vm.prank(registryDeployer);
        pluginRegistry.addPlugin(plugin);
    }

    function test_state_removePlugin() external {
        _setUp_removePlugin();

        string memory name = "MockERC20";

        assertEq(true, pluginRegistry.getPlugin(name).metadata.implementation != address(0));

        vm.prank(registryDeployer);
        pluginRegistry.removePlugin(name);

        vm.expectRevert("PluginRegistry: plugin does not exist.");
        pluginRegistry.getPlugin(name);

        vm.expectRevert("PluginRegistry: no plugin for function.");
        pluginRegistry.getPluginForFunction(MockERC20.mint.selector);

        vm.expectRevert("PluginRegistry: no plugin for function.");
        pluginRegistry.getPluginForFunction(MockERC20.toggleTax.selector);

        // Re-add plugin with 1 less function (to check if the info for the other function got deleted.)
        Plugin memory plugin;

        plugin.metadata = PluginMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        plugin.functions = new PluginFunction[](1);
        plugin.functions[0] = PluginFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        pluginRegistry.addPlugin(plugin);

        vm.expectRevert("PluginRegistry: no plugin for function.");
        pluginRegistry.getPluginForFunction(MockERC20.toggleTax.selector);

        PluginFunction[] memory functions = pluginRegistry.getAllFunctionsOfPlugin(name);
        assertEq(functions.length, 1);
        assertEq(functions[0].functionSelector, MockERC20.mint.selector);
    }

    function test_revert_removePlugin_unauthorizedCaller() external {
        _setUp_removePlugin();

        string memory name = "MockERC20";

        vm.expectRevert();
        pluginRegistry.removePlugin(name);
    }

    function test_revert_removePlugin_pluginDoesNotExist() external {
        string memory name = "MockERC20";

        vm.prank(registryDeployer);
        vm.expectRevert("PluginState: plugin does not exist.");
        pluginRegistry.removePlugin(name);
    }
}
