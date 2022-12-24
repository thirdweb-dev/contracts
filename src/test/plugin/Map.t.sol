// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/Map.sol";
import "contracts/extension/plugin/RouterImmutable.sol";
import { BaseTest } from "../utils/BaseTest.sol";
import "contracts/lib/TWStrings.sol";

contract MapTest is BaseTest {
    using TWStrings for uint256;
    RouterImmutable internal router;

    address[] private pluginAddresses;
    IMap.Plugin[] private plugins;

    function setUp() public override {
        super.setUp();

        uint256 total = 50;

        address pluginAddress;

        for (uint256 i = 0; i < total; i += 1) {
            if (i % 10 == 0) {
                pluginAddress = address(uint160(0x50000 + i));
                pluginAddresses.push(pluginAddress);
            }
            plugins.push(IMap.Plugin(bytes4(keccak256(abi.encodePacked(i.toString()))), pluginAddress, i.toString()));
        }

        router = new RouterImmutable(plugins);
    }

    function test_state_getPluginForFunction() external {
        uint256 len = plugins.length;
        for (uint256 i = 0; i < len; i += 1) {
            address pluginAddress = plugins[i].pluginAddress;
            bytes4 selector = plugins[i].selector;

            assertEq(pluginAddress, router.getPluginForFunction(selector));
        }
    }

    function test_state_getAllFunctionsOfPlugin() external {
        uint256 len = plugins.length;
        for (uint256 i = 0; i < len; i += 1) {
            address pluginAddress = plugins[i].pluginAddress;

            uint256 expectedNum;

            for (uint256 j = 0; j < plugins.length; j += 1) {
                if (plugins[j].pluginAddress == pluginAddress) {
                    expectedNum += 1;
                }
            }

            bytes4[] memory expectedFns = new bytes4[](expectedNum);
            uint256 idx;

            for (uint256 j = 0; j < plugins.length; j += 1) {
                if (plugins[j].pluginAddress == pluginAddress) {
                    expectedFns[idx] = plugins[j].selector;
                    idx += 1;
                }
            }

            bytes4[] memory fns = router.getAllFunctionsOfPlugin(pluginAddress);

            assertEq(fns.length, expectedNum);

            for (uint256 k = 0; k < fns.length; k += 1) {
                assertEq(fns[k], expectedFns[k]);
            }
        }
    }

    function test_state_getAllRegistered() external {
        IMap.Plugin[] memory pluginsStored = router.getAllPlugins();

        for (uint256 i = 0; i < pluginsStored.length; i += 1) {
            assertEq(pluginsStored[i].pluginAddress, plugins[i].pluginAddress);
            assertEq(pluginsStored[i].selector, plugins[i].selector);
        }
    }
}
