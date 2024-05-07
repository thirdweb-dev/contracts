// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports

import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC1155Test_setSaleRecipientForToken is BaseTest {
    using Strings for uint256;

    DropERC1155 public drop;

    address private unauthorized = address(0x123);
    address private recipient = address(0x456);

    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerWithoutAdminRole() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerWithAdminRole() {
        vm.startPrank(deployer);
        _;
    }

    function test_revert_NoAdminRole() public callerWithoutAdminRole {
        bytes32 role = bytes32(0x00);
        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, unauthorized, role)
        );
        drop.setSaleRecipientForToken(0, recipient);
    }

    function test_state() public callerWithAdminRole {
        drop.setSaleRecipientForToken(0, recipient);
        address newSaleRecipient = drop.saleRecipient(0);
        assertEq(newSaleRecipient, recipient);
    }

    function test_event() public callerWithAdminRole {
        vm.expectEmit(true, true, false, false);
        emit SaleRecipientForTokenUpdated(0, recipient);
        drop.setSaleRecipientForToken(0, recipient);
    }
}
