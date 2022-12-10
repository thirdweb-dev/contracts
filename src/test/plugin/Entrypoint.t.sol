// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/Map.sol";
import "contracts/extension/plugin/Entrypoint.sol";
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

contract EntrypointTest is BaseTest {
    address entrypoint;

    function setUp() public override {
        super.setUp();

        address counter = address(new Counter());

        IMap.ExtensionMap[] memory extensionMaps = new IMap.ExtensionMap[](2);
        extensionMaps[0] = IMap.ExtensionMap(Counter.number.selector, counter);
        extensionMaps[1] = IMap.ExtensionMap(Counter.setNumber.selector, counter);

        address map = address(new Map(extensionMaps));
        entrypoint = address(new Entrypoint(map));
    }

    function test_state_callWithEntrypoint() external {
        uint256 num = 5;

        Counter(entrypoint).setNumber(num);

        assertEq(Counter(entrypoint).number(), num);
    }

    function test_revert_callWithEntrypoint() external {
        vm.expectRevert("No extension available for selector.");
        Counter(entrypoint).doubleNumber();
    }
}
