// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/Map.sol";
import "contracts/extension/plugin/Router.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract RouterImplementation is Router {
    constructor(Plugin[] memory _pluginsToRegister) Router(_pluginsToRegister) {}

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

        IMap.Plugin[] memory pluginMaps = new IMap.Plugin[](3);
        pluginMaps[0] = IMap.Plugin(Counter.number.selector, counter, "number()");
        pluginMaps[1] = IMap.Plugin(Counter.setNumber.selector, counter, "setNumber(uint256)");
        pluginMaps[2] = IMap.Plugin(Counter.doubleNumber.selector, counter, "doubleNumber()");

        router = address(new RouterImplementation(pluginMaps));
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
            IMap.Plugin(Counter.doubleNumber.selector, counterAlternate, "doubleNumber()")
        );

        // Double number. Fixed: it doubles the number.
        Counter(router).doubleNumber();
        assertEq(Counter(router).number(), num * 2);

        // Get and check all overriden extensions.
        IMap.Plugin[] memory pluginsStored = RouterImplementation(payable(router)).getAllPlugins();
        assertEq(pluginsStored.length, 3);

        for (uint256 i = 0; i < pluginsStored.length; i += 1) {
            if (pluginsStored[i].selector == Counter.doubleNumber.selector) {
                assertEq(pluginsStored[i].pluginAddress, counterAlternate);
            }
        }
    }
}
