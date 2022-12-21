// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/Map.sol";
import "contracts/extension/plugin/RouterImmutable.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract Counter {
    uint256 private number_;

    function number() external view returns (uint256) {
        return number_;
    }

    function setNumber(uint256 _newNum) external {
        number_ = _newNum;
    }

    function doubleNumber() external {
        number_ *= 2;
    }
}

contract RouterImmutableTest is BaseTest {
    address router;

    function setUp() public override {
        super.setUp();

        address counter = address(new Counter());

        IMap.Plugin[] memory pluginMaps = new IMap.Plugin[](2);
        pluginMaps[0] = IMap.Plugin(Counter.number.selector, counter, "number()");
        pluginMaps[1] = IMap.Plugin(Counter.setNumber.selector, counter, "setNumber(uint256)");

        router = address(new RouterImmutable(pluginMaps));
    }

    function test_state_callWithRouter() external {
        uint256 num = 5;

        Counter(router).setNumber(num);

        assertEq(Counter(router).number(), num);
    }

    function test_revert_callWithRouter() external {
        vm.expectRevert("Map: No plugin available for selector");
        Counter(router).doubleNumber();
    }
}
