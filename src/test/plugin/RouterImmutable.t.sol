// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/PluginMap.sol";
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
    address internal map;
    address internal router;

    function setUp() public override {
        super.setUp();

        address counter = address(new Counter());

        IPluginMap.Plugin[] memory pluginMaps = new IPluginMap.Plugin[](2);
        pluginMaps[0] = IPluginMap.Plugin(Counter.number.selector, "number()", counter);
        pluginMaps[1] = IPluginMap.Plugin(Counter.setNumber.selector, "setNumber(uint256)", counter);

        map = address(new PluginMap(pluginMaps));
        router = address(new RouterImmutable(map));
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
