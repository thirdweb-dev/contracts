// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports

import "../../../utils/BaseTest.sol";

contract DropERC721Test_setMaxTotalSupply is BaseTest {
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    DropERC721 public drop;

    address private unauthorized = address(0x123);

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerNotAdmin() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerAdmin() {
        vm.startPrank(deployer);
        _;
    }

    function test_revert_CallerNotAdmin() public callerNotAdmin {
        bytes32 role = bytes32(0x00);
        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, unauthorized, role)
        );
        drop.setMaxTotalSupply(0);
    }

    function test_state() public callerAdmin {
        drop.setMaxTotalSupply(0);
        assertEq(drop.maxTotalSupply(), 0);
    }

    function test_event() public callerAdmin {
        vm.expectEmit(false, false, false, false);
        emit MaxTotalSupplyUpdated(0);
        drop.setMaxTotalSupply(0);
    }
}
