// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { PrimarySale } from "contracts/extension/PrimarySale.sol";

contract MyPrimarySale is PrimarySale {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return condition;
    }
}

contract ExtensionPrimarySale is DSTest, Test {
    MyPrimarySale internal ext;
    event PrimarySaleRecipientUpdated(address indexed recipient);

    function setUp() public {
        ext = new MyPrimarySale();
    }

    function test_state_setPrimarySaleRecipient() public {
        ext.setCondition(true);

        address _primarySaleRecipient = address(0x123);
        ext.setPrimarySaleRecipient(_primarySaleRecipient);

        address recipient = ext.primarySaleRecipient();
        assertEq(recipient, _primarySaleRecipient);
    }

    function test_revert_setPrimarySaleRecipient_NotAuthorized() public {
        address _primarySaleRecipient = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(PrimarySale.PrimarySaleUnauthorized.selector));
        ext.setPrimarySaleRecipient(_primarySaleRecipient);
    }

    function test_event_setPrimarySaleRecipient() public {
        ext.setCondition(true);

        address _primarySaleRecipient = address(0x123);

        vm.expectEmit(true, true, true, true);
        emit PrimarySaleRecipientUpdated(_primarySaleRecipient);

        ext.setPrimarySaleRecipient(_primarySaleRecipient);
    }
}
