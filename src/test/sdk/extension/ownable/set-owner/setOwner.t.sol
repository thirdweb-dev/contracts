// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Ownable, IOwnable } from "contracts/extension/Ownable.sol";
import "../../ExtensionUtilTest.sol";

contract MyOwnable is Ownable {
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function _canSetOwner() internal view override returns (bool) {
        return msg.sender == admin;
    }
}

contract Ownable_SetOwner is ExtensionUtilTest {
    MyOwnable internal ext;
    address internal admin;
    address internal caller;
    address internal oldOwner;
    address internal newOwner;

    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    function setUp() public override {
        super.setUp();

        admin = getActor(0);
        caller = getActor(1);

        oldOwner = getActor(2);
        newOwner = getActor(3);

        ext = new MyOwnable(address(admin));

        vm.prank(address(admin));
        ext.setOwner(oldOwner);

        assertEq(oldOwner, ext.owner());
    }

    function test_setOwner_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorized.selector));
        ext.setOwner(newOwner);
    }

    modifier whenCallerAuthorized() {
        caller = admin;
        _;
    }

    function test_setOwner() public whenCallerAuthorized {
        vm.prank(address(caller));
        ext.setOwner(newOwner);

        assertEq(newOwner, ext.owner());
    }

    function test_setOwner_event() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectEmit(true, true, false, false);
        emit OwnerUpdated(oldOwner, newOwner);
        ext.setOwner(newOwner);
    }
}
