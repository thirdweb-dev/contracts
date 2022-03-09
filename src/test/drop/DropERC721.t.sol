// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/drop/DropERC721.sol";

// Test imports
import "../utils/BaseTest.sol";

contract BaseDropERC721Test is BaseTest {
    DropERC721 public drop;

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
    }

    function test_claimCondition_startIdAndCount() public {
        vm.startPrank(deployer);

        uint256 currentStartId = 0;
        uint256 count = 0;

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](2);
        conditions[0].startTimestamp = 0;
        conditions[1].startTimestamp = 1;

        drop.setClaimConditions(conditions, false);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, false);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, true);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 2);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, true);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 4);
        assertEq(count, 2);
    }

    function test_claimCondition_startPhase() public {
        vm.startPrank(deployer);

        uint256 activeConditionId = 0;

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](3);
        conditions[0].startTimestamp = 10;
        conditions[0].maxClaimableSupply = 11;
        conditions[0].quantityLimitPerTransaction = 12;
        conditions[0].waitTimeInSecondsBetweenClaims = 13;
        conditions[1].startTimestamp = 20;
        conditions[1].maxClaimableSupply = 21;
        conditions[1].quantityLimitPerTransaction = 22;
        conditions[1].waitTimeInSecondsBetweenClaims = 23;
        conditions[2].startTimestamp = 30;
        conditions[2].maxClaimableSupply = 31;
        conditions[2].quantityLimitPerTransaction = 32;
        conditions[2].waitTimeInSecondsBetweenClaims = 33;
        drop.setClaimConditions(conditions, false);

        vm.expectRevert("no active mint condition.");
        drop.getActiveClaimConditionId();

        vm.warp(10);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 0);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 10);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 11);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 12);
        assertEq(drop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 13);

        vm.warp(20);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 1);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 20);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 21);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 22);
        assertEq(drop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 23);

        vm.warp(30);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 2);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 30);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 31);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 32);
        assertEq(drop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 33);

        vm.warp(40);
        assertEq(drop.getActiveClaimConditionId(), 2);
    }

    function test_claimCondition_waitTimeInSecondsBetweenClaims() public {
        vm.startPrank(deployer);
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        drop.lazyMint(100, "ipfs://", bytes(""));
        drop.setClaimConditions(conditions, false);
        drop.claim(receiver, 1, address(0), 0, proofs, 0);

        vm.expectRevert("cannot claim yet.");
        drop.claim(receiver, 1, address(0), 0, proofs, 0);
    }

    function test_claimCondition_resetEligibility_waitTimeInSecondsBetweenClaims() public {
        vm.startPrank(deployer);
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        drop.lazyMint(100, "ipfs://", bytes(""));

        drop.setClaimConditions(conditions, false);
        drop.claim(receiver, 1, address(0), 0, proofs, 0);

        drop.setClaimConditions(conditions, true);
        drop.claim(receiver, 1, address(0), 0, proofs, 0);
    }
}
