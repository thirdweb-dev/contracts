// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/drop/DropERC1155.sol";

// Test imports
import "../utils/BaseTest.sol";

contract DropERC1155Test is BaseTest {
    DropERC1155 public drop;

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));
    }

    /*///////////////////////////////////////////////////////////////
                                Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_revert_claim_claimQty() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://");

        vm.prank(deployer);
        drop.setClaimConditions(0, conditions, false);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("invalid quantity claimed.");
        drop.claim(receiver, 0, 200, address(0), 0, proofs, 2);

        vm.prank(deployer);
        drop.setClaimConditions(0, conditions, true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("invalid quantity claimed.");
        drop.claim(receiver, 0, 200, address(0), 0, proofs, 1);
    }
}
