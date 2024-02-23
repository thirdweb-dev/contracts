// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Ownable } from "contracts/extension/Ownable.sol";

contract MyOwnable is Ownable {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetOwner() internal view override returns (bool) {
        return condition;
    }
}

contract ExtensionOwnableTest is DSTest, Test {
    MyOwnable internal ext;
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    function setUp() public {
        ext = new MyOwnable();
    }

    function test_state_setOwner() public {
        ext.setCondition(true);

        address owner = address(0x123);
        ext.setOwner(owner);

        address currentOwner = ext.owner();
        assertEq(currentOwner, owner);
    }

    function test_revert_setOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorized.selector));
        ext.setOwner(address(0x1234));
    }

    function test_event_setOwner() public {
        ext.setCondition(true);

        address owner = address(0x123);

        vm.expectEmit(true, true, true, true);
        emit OwnerUpdated(address(0), owner);

        ext.setOwner(owner);
    }
}
