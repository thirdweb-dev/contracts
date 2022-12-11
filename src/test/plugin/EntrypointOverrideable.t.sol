// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/Map.sol";
import "contracts/extension/plugin/EntrypointOverrideable.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract Entrypoint is EntrypointOverrideable {
    constructor(address _functionMap) EntrypointOverrideable(_functionMap) {}

    function _canOverrideExtensions() internal pure override returns (bool) {
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

contract EntrypointOverrideableTest is BaseTest {
    address internal map;
    address internal entrypoint;

    address internal counter;
    address internal counterAlternate;

    function setUp() public override {
        super.setUp();

        counter = address(new Counter());
        counterAlternate = address(new CounterAlternate());

        IMap.ExtensionMap[] memory extensionMaps = new IMap.ExtensionMap[](3);
        extensionMaps[0] = IMap.ExtensionMap(Counter.number.selector, counter);
        extensionMaps[1] = IMap.ExtensionMap(Counter.setNumber.selector, counter);
        extensionMaps[2] = IMap.ExtensionMap(Counter.doubleNumber.selector, counter);

        map = address(new Map(extensionMaps));
        entrypoint = address(new Entrypoint(map));
    }

    function test_state_overrideExtensionForFunction() external {
        // Set number.
        uint256 num = 5;
        Counter(entrypoint).setNumber(num);
        assertEq(Counter(entrypoint).number(), num);

        // Double number. Bug: it quadruples the number.
        Counter(entrypoint).doubleNumber();
        assertEq(Counter(entrypoint).number(), num * 4);

        // Reset number.
        Counter(entrypoint).setNumber(num);
        assertEq(Counter(entrypoint).number(), num);

        // Fix the extension for `doubleNumber`.
        Entrypoint(payable(entrypoint)).overrideExtensionForFunction(Counter.doubleNumber.selector, counterAlternate);

        // Double number. Fixed: it doubles the number.
        Counter(entrypoint).doubleNumber();
        assertEq(Counter(entrypoint).number(), num * 2);

        // Get and check all overriden extensions.
        IEntrypointOverrideable.ExtensionMap[] memory extensionMapsStored = Entrypoint(payable(entrypoint))
            .getAllOverriden();
        assertEq(extensionMapsStored.length, 1);
        assertEq(extensionMapsStored[0].extension, counterAlternate);
        assertEq(extensionMapsStored[0].selector, Counter.doubleNumber.selector);
    }
}
