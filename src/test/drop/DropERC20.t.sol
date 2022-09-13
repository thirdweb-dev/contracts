// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/drop/DropERC20.sol";

// Test imports
import "../utils/BaseTest.sol";

contract DropERC20Test is BaseTest {
    DropERC20 public drop;

    function setUp() public override {
        super.setUp();
        drop = DropERC20(getContract("DropERC20"));
    }

    function test_claimCondition_quantityLimitPerWallet() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC20.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 10, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), address(getActor(5))), 10);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 10, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), address(getActor(5))), 20);

        vm.expectRevert("invalid quantity claimed.");
        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 90, address(0), 0, alp, "");
    }

    function test_claimCondition_resetEligibility_quantityLimitPerWallet() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC20.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 10, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), address(getActor(5))), 10);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, true);
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), address(getActor(5))), 0);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 10, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), address(getActor(5))), 10);
    }

    /*///////////////////////////////////////////////////////////////
                                Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_revert_claim_claimQty() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC20.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.maxQuantityInAllowlist = 1;

        DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        // vm.prank(deployer);
        // drop.setMaxTotalSupply(10_000);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("invalid quantity claimed.");
        drop.claim(receiver, 200, address(0), 0, alp, "");

        vm.prank(deployer);
        drop.setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("invalid quantity claimed.");
        drop.claim(receiver, 200, address(0), 0, alp, "");
    }

    function test_state_claim_timestamps() public {
        vm.warp(100);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC20.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.maxQuantityInAllowlist = 1;

        DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = drop.getClaimTimestamp(0, getActor(5));
        assertEq(lastClaimTimestamp, 0);
        assertEq(nextValidClaimTimestamp, 0);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 50, address(0), 0, alp, "");

        (lastClaimTimestamp, nextValidClaimTimestamp) = drop.getClaimTimestamp(0, getActor(5));
        assertEq(lastClaimTimestamp, 100);
        assertEq(nextValidClaimTimestamp, type(uint256).max);
    }

    function test_revert_claim_timestamps() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC20.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.maxQuantityInAllowlist = 1;

        DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 50, address(0), 0, alp, "");

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("cannot claim yet.");
        drop.claim(receiver, 50, address(0), 0, alp, "");
    }
}
