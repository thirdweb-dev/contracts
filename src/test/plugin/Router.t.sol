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
    bytes32 public constant COUNTER_STORAGE_POSITION = keccak256("counter.storage");

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

contract CounterAlternate {
    function doubleNumber() external {
        CounterStorage.Data storage data = CounterStorage.counterStorage();
        data.number *= 2; // Fixed!
    }
}

contract RouterTest is BaseTest {
    address internal map;
    address internal router;

    address internal counter;
    address internal counterAlternate;

    function setUp() public override {
        super.setUp();

        counter = address(new Counter());
        counterAlternate = address(new CounterAlternate());

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

        // Double number. Bug: it quadruples the number.
        Counter(router).doubleNumber();
        assertEq(Counter(router).number(), num * 4);

        // Reset number.
        Counter(router).setNumber(num);
        assertEq(Counter(router).number(), num);

        // Fix the extension for `doubleNumber`.
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counterAlternate)
        );

        // Double number. Fixed: it doubles the number.
        Counter(router).doubleNumber();
        assertEq(Counter(router).number(), num * 2);

        // Get and check all overriden extensions.
        IPluginMap.Plugin[] memory pluginsStored = RouterImplementation(payable(router)).getAllPlugins();
        assertEq(pluginsStored.length, 3);

        for (uint256 i = 0; i < pluginsStored.length; i += 1) {
            if (pluginsStored[i].functionSelector == Counter.doubleNumber.selector) {
                assertEq(pluginsStored[i].pluginAddress, counterAlternate);
            }
        }
    }

    function test_state_getAllFunctionsOfPlugin() public {
        // add fixed function from counterAlternate
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counterAlternate)
        );

        // add previously not added function of counter
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.extraFunction.selector, "extraFunction()", counter)
        );

        // re-add an already added function of counter
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.number.selector, "number()", counter)
        );

        // check plugins for counter
        bytes4[] memory functions = RouterImplementation(payable(router)).getAllFunctionsOfPlugin(counter);
        assertEq(functions.length, 4);
        console.logBytes4(functions[0]);
        console.logBytes4(functions[1]);
        console.logBytes4(functions[2]);
        console.logBytes4(functions[3]);

        // check plugins for counterAlternate
        functions = RouterImplementation(payable(router)).getAllFunctionsOfPlugin(counterAlternate);
        assertEq(functions.length, 1);
        console.logBytes4(functions[0]);
    }

    function test_state_getPluginForFunction() public {
        // add fixed function from counterAlternate
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.doubleNumber.selector, "doubleNumber()", counterAlternate)
        );

        // add previously not added function of counter
        RouterImplementation(payable(router)).addPlugin(
            IPluginMap.Plugin(Counter.extraFunction.selector, "extraFunction()", counter)
        );

        address pluginAddress = RouterImplementation(payable(router)).getPluginForFunction(
            Counter.doubleNumber.selector
        );
        assertEq(pluginAddress, counterAlternate);

        pluginAddress = RouterImplementation(payable(router)).getPluginForFunction(Counter.extraFunction.selector);
        assertEq(pluginAddress, counter);
    }
}
