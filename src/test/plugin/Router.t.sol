// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/PluginMap.sol";
import "contracts/extension/plugin/Router.sol";
import { BaseTest } from "../utils/BaseTest.sol";
import "lib/forge-std/src/console.sol";

contract RouterImplementation is Router {
    constructor(address _functionMap) Router(_functionMap) {}

    function _canSetPlugin() internal pure override returns (bool) {
        return true;
    }
}

library CounterStorage {
    /// @custom:storage-location erc7201:counter.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("counter.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant COUNTER_STORAGE_POSITION =
        0x3a8940d2c88113c2296117248b8b2aedcf41634993b4c0b4ea1a36805e66c300;

    struct Data {
        uint256 number;
    }

    function counterStorage() internal pure returns (Data storage counterData) {
        bytes32 position = COUNTER_STORAGE_POSITION;
        assembly {
            counterData.slot := position
        }
    }
}

contract Counter {
    function number() external view returns (uint256) {
        CounterStorage.Data storage data = CounterStorage.counterStorage();
        return data.number;
    }

    function setNumber(uint256 _newNum) external {
        CounterStorage.Data storage data = CounterStorage.counterStorage();
        data.number = _newNum;
    }

    function doubleNumber() external {
        CounterStorage.Data storage data = CounterStorage.counterStorage();
        data.number *= 4; // Buggy!
    }

    function extraFunction() external pure {}
}

contract CounterAlternate1 {
    function doubleNumber() external {
        CounterStorage.Data storage data = CounterStorage.counterStorage();
        data.number *= 2; // Fixed!
    }
}

contract CounterAlternate2 {
    function tripleNumber() external {
        CounterStorage.Data storage data = CounterStorage.counterStorage();
        data.number *= 3; // Fixed!
    }
}

contract RouterTest is BaseTest {
    address internal map;
    address internal router;

    address internal counter;
    address internal counterAlternate1;
    address internal counterAlternate2;

    function setUp() public override {
        super.setUp();

        counter = address(new Counter());
        counterAlternate1 = address(new CounterAlternate1());
        counterAlternate2 = address(new CounterAlternate2());

        IPluginMap.Plugin[] memory pluginMaps = new IPluginMap.Plugin[](3);
        pluginMaps[0] = IPluginMap.Plugin(Counter.number.selector, "number()", counter);
        pluginMaps[1] = IPluginMap.Plugin(Counter.setNumber.selector, "setNumber(uint256)", counter);
        pluginMaps[2] = IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counter);

        map = address(new PluginMap(pluginMaps));
        router = address(new RouterImplementation(map));
    }

    function test_state_addPlugin() external {
        // Set number.
        uint256 num = 5;
        Counter(router).setNumber(num);
        assertEq(Counter(router).number(), num);

        // Add extension for `tripleNumber`.
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(CounterAlternate2.tripleNumber.selector, "tripleNumber()", counterAlternate2)
        );

        // Triple number.
        CounterAlternate2(router).tripleNumber();
        assertEq(Counter(router).number(), num * 3);

        // Get and check all overriden extensions.
        IPluginMap.Plugin[] memory pluginsStored = RouterImplementation(payable(router)).getAllPlugins();
        assertEq(pluginsStored.length, 4);

        bool isStored;

        for (uint256 i = 0; i < pluginsStored.length; i += 1) {
            if (pluginsStored[i].functionSelector == CounterAlternate2.tripleNumber.selector) {
                isStored = true;
                assertEq(pluginsStored[i].pluginAddress, counterAlternate2);
            }
        }

        assertTrue(isStored);
    }

    function test_revert_addPlugin_defaultExists() external {
        vm.expectRevert("Router: default plugin exists for function.");
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counterAlternate1)
        );
    }

    function test_revert_addPlugin_pluginAlreadyExists() external {
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(CounterAlternate2.tripleNumber.selector, "tripleNumber()", counterAlternate2)
        );
        vm.expectRevert();
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(CounterAlternate2.tripleNumber.selector, "tripleNumber()", counterAlternate2)
        );
    }

    function test_revert_addPlugin_selectorSignatureMismatch() external {
        vm.expectRevert("Router: fn selector and signature mismatch.");
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(CounterAlternate2.tripleNumber.selector, "doubleNumber()", counterAlternate2)
        );
    }

    function test_state_updatePlugin() external {
        // Set number.
        uint256 num = 5;
        Counter(router).setNumber(num);
        assertEq(Counter(router).number(), num);

        // Double number. Bug: it quadruples the number.
        Counter(router).doubleNumber();
        assertEq(Counter(router).number(), num * 4);

        // Reset number.
        Counter(router).setNumber(num);
        assertEq(Counter(router).number(), num);

        // Fix the extension for `doubleNumber`.
        RouterImplementation(payable(router)).updatePlugin(
            IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counterAlternate1)
        );

        // Double number. Fixed: it doubles the number.
        Counter(router).doubleNumber();
        assertEq(Counter(router).number(), num * 2);

        // Get and check all overriden extensions.
        assertEq(
            RouterImplementation(payable(router)).getPluginForFunction(Counter.doubleNumber.selector),
            counterAlternate1
        );

        IPluginMap.Plugin[] memory pluginsStored = RouterImplementation(payable(router)).getAllPlugins();
        assertEq(pluginsStored.length, 3);

        bool isStored;

        for (uint256 i = 0; i < pluginsStored.length; i += 1) {
            if (pluginsStored[i].functionSelector == Counter.doubleNumber.selector) {
                assertEq(pluginsStored[i].pluginAddress, counterAlternate1);
                isStored = true;
            }
        }

        assertTrue(isStored);
    }

    function test_state_getAllFunctionsOfPlugin() public {
        // add fixed function from counterAlternate
        RouterImplementation(payable(router)).updatePlugin(
            IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counterAlternate1)
        );

        // add previously not added function of counter
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.extraFunction.selector, "extraFunction()", counter)
        );

        // check plugins for counter
        bytes4[] memory functions = RouterImplementation(payable(router)).getAllFunctionsOfPlugin(counter);
        assertEq(functions.length, 4);
        console.logBytes4(functions[0]);
        console.logBytes4(functions[1]);
        console.logBytes4(functions[2]);
        console.logBytes4(functions[3]);

        // check plugins for counterAlternate
        functions = RouterImplementation(payable(router)).getAllFunctionsOfPlugin(counterAlternate1);
        assertEq(functions.length, 1);
        console.logBytes4(functions[0]);
    }

    function test_revert_updatePlugin_selectorSignatureMismatch() external {
        vm.expectRevert("Router: fn selector and signature mismatch.");
        RouterImplementation(payable(router)).updatePlugin(
            IPluginMap.Plugin(CounterAlternate1.doubleNumber.selector, "tripleNumber()", counterAlternate2)
        );
    }

    function test_revert_updatePlugin_functionDNE() external {
        vm.expectRevert("Map: No plugin available for selector");
        RouterImplementation(payable(router)).updatePlugin(
            IPluginMap.Plugin(CounterAlternate2.tripleNumber.selector, "tripleNumber()", counterAlternate2)
        );
    }

    function test_state_removePlugin() external {
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(CounterAlternate2.tripleNumber.selector, "tripleNumber()", counterAlternate2)
        );

        assertEq(
            RouterImplementation(payable(router)).getPluginForFunction(CounterAlternate2.tripleNumber.selector),
            counterAlternate2
        );

        RouterImplementation(payable(router)).removePlugin(CounterAlternate2.tripleNumber.selector);

        vm.expectRevert("Map: No plugin available for selector");
        RouterImplementation(payable(router)).getPluginForFunction(CounterAlternate2.tripleNumber.selector);
    }

    function test_revert_removePlugin_pluginDNE() external {
        vm.expectRevert("Router: No plugin available for selector");
        RouterImplementation(payable(router)).removePlugin(CounterAlternate2.tripleNumber.selector);
    }

    function test_state_getPluginForFunction() public {
        // add fixed function from counterAlternate
        RouterImplementation(payable(router)).updatePlugin(
            IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counterAlternate1)
        );

        // add previously not added function of counter
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.extraFunction.selector, "extraFunction()", counter)
        );

        address pluginAddress = RouterImplementation(payable(router)).getPluginForFunction(
            Counter.doubleNumber.selector
        );
        assertEq(pluginAddress, counterAlternate1);

        pluginAddress = RouterImplementation(payable(router)).getPluginForFunction(Counter.extraFunction.selector);
        assertEq(pluginAddress, counter);
    }
}
