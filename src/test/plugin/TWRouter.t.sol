// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/plugin/interface/IPlugin.sol";
import "contracts/plugin/PluginRegistry.sol";
import "contracts/plugin/TWRouter.sol";

import { BaseTest } from "../utils/BaseTest.sol";
import { TWProxy } from "contracts/TWProxy.sol";

contract TWRouterImplementation is TWRouter {
    constructor(address _pluginRegistry, string[] memory _pluginNames) TWRouter(_pluginRegistry, _pluginNames) {}

    function _canSetPlugin() internal view virtual override returns (bool) {
        return true;
    }
}

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

contract ContractD {
    uint256 private d_;

    function d() external {
        d_ += 1;
    }

    function getD() external view returns (uint256) {
        return d_;
    }
}

contract TWRouterTest is BaseTest, IPlugin {
    address private router;
    address private registryDeployer;

    PluginRegistry private pluginRegistry;

    mapping(uint256 => Plugin) private plugins;

    function _setupPlugins() private returns (string[] memory pluginNames) {
        pluginNames = new string[](3);

        // Add plugin 1.

        plugins[0].metadata = PluginMetadata({
            name: "ContractA",
            metadataURI: "ipfs://ContractA",
            implementation: address(new ContractA())
        });

        plugins[0].functions.push(PluginFunction(ContractA.a.selector, "a()"));

        pluginNames[0] = plugins[0].metadata.name;

        // Add plugin 2.

        plugins[1].metadata = PluginMetadata({
            name: "ContractB",
            metadataURI: "ipfs://ContractB",
            implementation: address(new ContractB())
        });
        plugins[1].functions.push(PluginFunction(ContractB.b.selector, "b()"));

        pluginNames[1] = plugins[1].metadata.name;

        // Add plugin 3.

        plugins[2].metadata = PluginMetadata({
            name: "ContractC",
            metadataURI: "ipfs://ContractC",
            implementation: address(new ContractC())
        });
        plugins[2].functions.push(PluginFunction(ContractC.c.selector, "c()"));
        plugins[2].functions.push(PluginFunction(ContractC.getC.selector, "getC()"));

        pluginNames[2] = plugins[2].metadata.name;
    }

    function setUp() public override {
        super.setUp();

        // Set up plugin registry.
        registryDeployer = address(0x123);

        vm.prank(registryDeployer);
        pluginRegistry = new PluginRegistry(registryDeployer);

        // Set up plugins
        string[] memory pluginNames = _setupPlugins();
        uint256 len = pluginNames.length;

        for (uint256 i = 0; i < len; i += 1) {
            vm.prank(registryDeployer);
            pluginRegistry.addPlugin(plugins[i]);
        }

        // Deploy TWRouter implementation
        address routerImpl = address(new TWRouterImplementation(address(pluginRegistry), pluginNames));

        // Deploy proxy to router.
        router = address(new TWProxy(routerImpl, ""));
    }

    // ==================== Initial state ====================

    function test_state_initialState() external {
        TWRouter twRouter = TWRouter(payable(router));

        Plugin[] memory getAllPlugins = twRouter.getAllPlugins();
        uint256 len = 3;

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
            Plugin memory plugin = twRouter.getPlugin(plugins[i].metadata.name);
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
            PluginFunction[] memory functions = twRouter.getAllFunctionsOfPlugin(name);
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
                PluginMetadata memory plugin = twRouter.getPluginForFunction(functions[j].functionSelector);
                assertEq(plugin.implementation, metadata.implementation);
                assertEq(plugin.name, metadata.name);
                assertEq(plugin.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, twRouter.getPluginImplementation(metadata.name));
        }

        // Test contract call
        uint256 cBefore = ContractC(router).getC();
        ContractC(router).c();

        assertEq(cBefore + 1, ContractC(router).getC());
    }

    // ==================== Add plugins ====================

    function _setupAddPlugin() private {
        // Add new plugin to registry

        plugins[3].metadata = PluginMetadata({
            name: "ContractD",
            metadataURI: "ipfs://ContractD",
            implementation: address(new ContractD())
        });
        plugins[3].functions.push(PluginFunction(ContractD.d.selector, "d()"));
        plugins[3].functions.push(PluginFunction(ContractD.getD.selector, "getD()"));

        vm.prank(registryDeployer);
        pluginRegistry.addPlugin(plugins[3]);
    }

    function test_state_addPlugin() external {
        _setupAddPlugin();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addPlugin(plugins[3].metadata.name);

        // getPlugin
        Plugin memory plugin = twRouter.getPlugin(plugins[3].metadata.name);
        assertEq(plugin.metadata.implementation, plugins[3].metadata.implementation);
        assertEq(plugin.metadata.name, plugins[3].metadata.name);
        assertEq(plugin.metadata.metadataURI, plugins[3].metadata.metadataURI);
        uint256 fnsLen = plugins[3].functions.length;
        assertEq(fnsLen, plugin.functions.length);
        for (uint256 j = 0; j < fnsLen; j += 1) {
            assertEq(plugins[3].functions[j].functionSelector, plugin.functions[j].functionSelector);
            assertEq(plugins[3].functions[j].functionSignature, plugin.functions[j].functionSignature);
        }
    }

    function test_revert_addPlugin_pluginDNE() external {
        _setupAddPlugin();

        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("PluginRegistry: plugin does not exist.");
        twRouter.addPlugin("Random name");
    }

    function test_revert_addPlugin_pluginAlreadyExists() external {
        _setupAddPlugin();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addPlugin(plugins[3].metadata.name);

        vm.expectRevert("PluginState: plugin already exists.");
        twRouter.addPlugin(plugins[3].metadata.name);
    }

    // ==================== Update plugins ====================

    function _setupUpdatePlugin() private {
        _setupAddPlugin();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addPlugin(plugins[3].metadata.name);

        // Update plugin to registry
        plugins[3].metadata.implementation = address(new ContractD());

        vm.prank(registryDeployer);
        pluginRegistry.updatePlugin(plugins[3]);
    }

    function test_state_updatePlugin() external {
        _setupUpdatePlugin();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.updatePlugin(plugins[3].metadata.name);

        // getPlugin
        Plugin memory plugin = twRouter.getPlugin(plugins[3].metadata.name);
        assertEq(plugin.metadata.implementation, plugins[3].metadata.implementation);
        assertEq(plugin.metadata.name, plugins[3].metadata.name);
        assertEq(plugin.metadata.metadataURI, plugins[3].metadata.metadataURI);
        uint256 fnsLen = plugins[3].functions.length;
        assertEq(fnsLen, plugin.functions.length);
        for (uint256 j = 0; j < fnsLen; j += 1) {
            assertEq(plugins[3].functions[j].functionSelector, plugin.functions[j].functionSelector);
            assertEq(plugins[3].functions[j].functionSignature, plugin.functions[j].functionSignature);
        }
    }

    function test_revert_updatePlugin_pluginDNE_inRegistry() external {
        _setupUpdatePlugin();

        vm.prank(registryDeployer);
        pluginRegistry.removePlugin(plugins[3].metadata.name);

        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("PluginRegistry: plugin does not exist.");
        twRouter.updatePlugin(plugins[3].metadata.name);
    }

    function test_revert_updatePlugin_pluginDNE_inRouter() external {
        _setupAddPlugin();

        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("PluginState: plugin does not exist.");
        twRouter.updatePlugin(plugins[3].metadata.name);
    }

    function test_revert_updatePlugin_reAddingPlugin() external {
        _setupAddPlugin();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addPlugin(plugins[3].metadata.name);

        vm.expectRevert("PluginState: re-adding same plugin.");
        twRouter.updatePlugin(plugins[3].metadata.name);
    }

    // ==================== Remove plugins ====================

    function _setupRemovePlugin() private {
        _setupAddPlugin();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addPlugin(plugins[3].metadata.name);
    }

    function test_state_removePlugin() external {
        _setupRemovePlugin();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.removePlugin(plugins[3].metadata.name);

        vm.expectRevert("PluginMap: plugin does not exist.");
        twRouter.getPlugin(plugins[3].metadata.name);
    }

    function test_revert_removePlugin_pluginDNE() external {
        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("PluginState: plugin does not exist.");
        twRouter.removePlugin("Random name");
    }
}
