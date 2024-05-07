// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract DropERC20Test_setMaxTotalSupply is BaseTest {
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    DropERC20 public drop;

    function setUp() public override {
        super.setUp();

        drop = DropERC20(getContract("DropERC20"));
    }

    modifier callerHasDefaultAdminRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier callerDoesNotHaveDefaultAdminRole() {
        _;
    }

    function test_revert_doesNotHaveAdminRole() public callerDoesNotHaveDefaultAdminRole {
        bytes32 role = bytes32(0x00);

        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, address(this), role)
        );
        drop.setMaxTotalSupply(0);
    }

    function test_state_callerHasDefaultAdminRole() public callerHasDefaultAdminRole {
        drop.setMaxTotalSupply(100);
        assertEq(drop.maxTotalSupply(), 100);
    }

    function test_event_callerHasDefaultAdminRole() public callerHasDefaultAdminRole {
        vm.expectEmit(false, false, false, true);
        emit MaxTotalSupplyUpdated(100);
        drop.setMaxTotalSupply(100);
    }
}
