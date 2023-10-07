// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC1155Test_setMaxTotalSupply is BaseTest {
    using StringsUpgradeable for uint256;

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
        bytes32 role = keccak256("METADATA_ROLE");
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(unauthorized), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(role), 32)
            )
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
