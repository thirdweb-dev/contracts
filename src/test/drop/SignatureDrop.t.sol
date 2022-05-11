// // SPDX-License-Identifier: Apache-2.0
// pragma solidity ^0.8.0;

// import { SignatureDrop } from "contracts/drop/SignatureDrop.sol";

// // Test imports
// import "../utils/BaseTest.sol";

// contract SignatureDropTest is BaseTest {
//     SignatureDrop public sigdrop;

//     function setUp() public override {
//         super.setUp();
//         sigdrop = SignatureDrop(getContract("SignatureDrop"));
//     }

//     function test_claimCondition_startIdAndCount() public {
//         vm.startPrank(deployer);

//         uint256 currentStartId = 0;
//         uint256 count = 0;

//         SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](2);
//         conditions[0].startTimestamp = 0;
//         conditions[0].maxClaimableSupply = 10;
//         conditions[1].startTimestamp = 1;
//         conditions[1].maxClaimableSupply = 10;

//         sigdrop.setClaimConditions(conditions, false, "");
//         (currentStartId, count) = sigdrop.claimCondition();
//         assertEq(currentStartId, 0);
//         assertEq(count, 2);

//         sigdrop.setClaimConditions(conditions, false, "");
//         (currentStartId, count) = sigdrop.claimCondition();
//         assertEq(currentStartId, 0);
//         assertEq(count, 2);

//         sigdrop.setClaimConditions(conditions, true, "");
//         (currentStartId, count) = sigdrop.claimCondition();
//         assertEq(currentStartId, 2);
//         assertEq(count, 2);

//         sigdrop.setClaimConditions(conditions, true, "");
//         (currentStartId, count) = sigdrop.claimCondition();
//         assertEq(currentStartId, 4);
//         assertEq(count, 2);
//     }

//     // function test_claimCondition_startPhase() public {
//     //     vm.startPrank(deployer);

//     //     uint256 activeConditionId = 0;

//     //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](3);
//     //     conditions[0].startTimestamp = 10;
//     //     conditions[0].maxClaimableSupply = 11;
//     //     conditions[0].quantityLimitPerTransaction = 12;
//     //     conditions[0].waitTimeInSecondsBetweenClaims = 13;
//     //     conditions[1].startTimestamp = 20;
//     //     conditions[1].maxClaimableSupply = 21;
//     //     conditions[1].quantityLimitPerTransaction = 22;
//     //     conditions[1].waitTimeInSecondsBetweenClaims = 23;
//     //     conditions[2].startTimestamp = 30;
//     //     conditions[2].maxClaimableSupply = 31;
//     //     conditions[2].quantityLimitPerTransaction = 32;
//     //     conditions[2].waitTimeInSecondsBetweenClaims = 33;
//     //     sigdrop.setClaimConditions(conditions, false);

//     //     vm.expectRevert("!CONDITION.");
//     //     sigdrop.getActiveClaimConditionId();

//     //     vm.warp(10);
//     //     activeConditionId = sigdrop.getActiveClaimConditionId();
//     //     assertEq(activeConditionId, 0);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).startTimestamp, 10);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).maxClaimableSupply, 11);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 12);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 13);

//     //     vm.warp(20);
//     //     activeConditionId = sigdrop.getActiveClaimConditionId();
//     //     assertEq(activeConditionId, 1);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).startTimestamp, 20);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).maxClaimableSupply, 21);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 22);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 23);

//     //     vm.warp(30);
//     //     activeConditionId = sigdrop.getActiveClaimConditionId();
//     //     assertEq(activeConditionId, 2);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).startTimestamp, 30);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).maxClaimableSupply, 31);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 32);
//     //     assertEq(sigdrop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 33);

//     //     vm.warp(40);
//     //     assertEq(sigdrop.getActiveClaimConditionId(), 2);
//     // }

//     // function test_claimCondition_waitTimeInSecondsBetweenClaims() public {
//     //     vm.warp(1);

//     //     address receiver = getActor(0);
//     //     bytes32[] memory proofs = new bytes32[](0);

//     //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
//     //     conditions[0].maxClaimableSupply = 100;
//     //     conditions[0].quantityLimitPerTransaction = 100;
//     //     conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

//     //     vm.prank(deployer);
//     //     sigdrop.lazyMint(100, "ipfs://", bytes(""));
//     //     vm.prank(deployer);
//     //     sigdrop.setClaimConditions(conditions, false);

//     //     vm.prank(getActor(5), getActor(5));
//     //     sigdrop.claim(receiver, 1, address(0), 0, proofs, 0);

//     //     vm.expectRevert("cannot claim.");
//     //     vm.prank(getActor(5), getActor(5));
//     //     sigdrop.claim(receiver, 1, address(0), 0, proofs, 0);
//     // }

//     // function test_claimCondition_resetEligibility_waitTimeInSecondsBetweenClaims() public {
//     //     vm.warp(1);

//     //     address receiver = getActor(0);
//     //     bytes32[] memory proofs = new bytes32[](0);

//     //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
//     //     conditions[0].maxClaimableSupply = 100;
//     //     conditions[0].quantityLimitPerTransaction = 100;
//     //     conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

//     //     vm.prank(deployer);
//     //     sigdrop.lazyMint(100, "ipfs://", bytes(""));

//     //     vm.prank(deployer);
//     //     sigdrop.setClaimConditions(conditions, false);

//     //     vm.prank(getActor(5), getActor(5));
//     //     sigdrop.claim(receiver, 1, address(0), 0, proofs, 0);

//     //     vm.prank(deployer);
//     //     sigdrop.setClaimConditions(conditions, true);

//     //     vm.prank(getActor(5), getActor(5));
//     //     sigdrop.claim(receiver, 1, address(0), 0, proofs, 0);
//     // }

//     // function test_multiple_claim_exploit() public {
//     //     MasterExploitContract masterExploit = new MasterExploitContract(address(sigdrop));

//     //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
//     //     conditions[0].maxClaimableSupply = 100;
//     //     conditions[0].quantityLimitPerTransaction = 1;
//     //     conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

//     //     vm.prank(deployer);
//     //     sigdrop.lazyMint(100, "ipfs://", bytes(""));

//     //     vm.prank(deployer);
//     //     sigdrop.setClaimConditions(conditions, false);

//     //     bytes32[] memory proofs = new bytes32[](0);

//     //     vm.startPrank(getActor(5));
//     //     vm.expectRevert(bytes("BOT"));
//     //     masterExploit.performExploit(
//     //         address(masterExploit),
//     //         conditions[0].quantityLimitPerTransaction,
//     //         conditions[0].currency,
//     //         conditions[0].pricePerToken,
//     //         proofs,
//     //         0
//     //     );
//     // }
// }