// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports

import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";

contract DropERC1155Test_setMaxTotalSupply is BaseTest {
    DropERC1155 public drop;

    address private unauthorized = address(0x123);

    uint256 private newMaxSupply = 100;
    string private updatedBaseURI = "ipfs://";

    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

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
        drop.setMaxTotalSupply(0, newMaxSupply);
    }

    function test_state() public callerWithAdminRole {
        drop.setMaxTotalSupply(0, newMaxSupply);
        uint256 newMaxTotalSupply = drop.maxTotalSupply(0);
        assertEq(newMaxSupply, newMaxTotalSupply);
    }

    function test_event() public callerWithAdminRole {
        vm.expectEmit(false, false, false, true);
        emit MaxTotalSupplyUpdated(0, newMaxSupply);
        drop.setMaxTotalSupply(0, newMaxSupply);
    }
}
