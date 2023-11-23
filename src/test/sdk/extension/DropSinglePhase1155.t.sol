// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { DropSinglePhase1155 } from "contracts/extension/DropSinglePhase1155.sol";

contract MyDropSinglePhase1155 is DropSinglePhase1155 {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetClaimConditions() internal view override returns (bool) {
        return condition;
    }

    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {}

    function _transferTokensOnClaim(address _to, uint256 _tokenId, uint256 _quantityBeingClaimed) internal override {}
}

contract ExtensionDropSinglePhase1155 is DSTest, Test {
    MyDropSinglePhase1155 internal ext;

    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 quantityClaimed
    );
    event ClaimConditionUpdated(
        uint256 indexed tokenId,
        MyDropSinglePhase1155.ClaimCondition condition,
        bool resetEligibility
    );

    function setUp() public {
        ext = new MyDropSinglePhase1155();
    }

    /*///////////////////////////////////////////////////////////////
                                Claim Tests
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing revert condition; exceed max claimable supply.
     */
    function test_revert_claimCondition_exceedMaxClaimableSupply() public {
        ext.setCondition(true);
        vm.warp(1);

        address receiver = address(0x123);
        address claimer1 = address(0x345);
        address claimer2 = address(0x567);
        bytes32[] memory proofs = new bytes32[](0);
        uint256 _tokenId = 0;

        MyDropSinglePhase1155.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase1155.ClaimCondition[] memory conditions = new MyDropSinglePhase1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(_tokenId, conditions[0], false);

        vm.prank(claimer1, claimer1);
        ext.claim(receiver, _tokenId, 100, address(0), 0, alp, "");

        vm.expectRevert("!MaxSupply");
        vm.prank(claimer2, claimer2);
        ext.claim(receiver, _tokenId, 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction when no allowlist present.
     */
    function test_fuzz_claim_noAllowlist(uint256 x) public {
        ext.setCondition(true);
        vm.assume(x != 0);
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        bytes32[] memory proofs = new bytes32[](0);
        uint256 _tokenId = 0;

        MyDropSinglePhase1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;

        MyDropSinglePhase1155.ClaimCondition[] memory conditions = new MyDropSinglePhase1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(_tokenId, conditions[0], false);

        bytes memory errorQty = "!Qty";

        vm.prank(claimer, claimer);
        vm.expectRevert(errorQty);
        ext.claim(receiver, _tokenId, 101, address(0), 0, alp, "");

        ext.setClaimConditions(_tokenId, conditions[0], true);

        vm.prank(claimer, claimer);
        vm.expectRevert(errorQty);
        ext.claim(receiver, _tokenId, 101, address(0), 0, alp, "");
    }

    /**
     *  note: Testing event emission on setClaimConditions.
     */
    function test_event_setClaimConditions() public {
        ext.setCondition(true);
        vm.warp(1);

        bytes32[] memory proofs = new bytes32[](0);
        uint256 _tokenId = 0;

        MyDropSinglePhase1155.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase1155.ClaimCondition[] memory conditions = new MyDropSinglePhase1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.expectEmit(true, true, true, true);
        emit ClaimConditionUpdated(_tokenId, conditions[0], false);

        ext.setClaimConditions(_tokenId, conditions[0], false);
    }

    /**
     *  note: Testing event emission on claim.
     */
    function test_event_claim() public {
        ext.setCondition(true);
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        bytes32[] memory proofs = new bytes32[](0);
        uint256 _tokenId = 0;

        MyDropSinglePhase1155.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase1155.ClaimCondition[] memory conditions = new MyDropSinglePhase1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(_tokenId, conditions[0], false);

        vm.startPrank(claimer, claimer);

        vm.expectEmit(true, true, true, true);
        emit TokensClaimed(claimer, receiver, _tokenId, 1);

        ext.claim(receiver, _tokenId, 1, address(0), 0, alp, "");
    }

    function test_claimCondition_resetEligibility_quantityLimitPerWallet() public {
        ext.setCondition(true);
        vm.warp(1);

        address receiver = address(0x123);
        bytes32[] memory proofs = new bytes32[](0);

        MyDropSinglePhase1155.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase1155.ClaimCondition[] memory conditions = new MyDropSinglePhase1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(0, conditions[0], false);

        vm.prank(receiver, receiver);
        ext.claim(receiver, 0, 10, address(0), 0, alp, "");
        assertEq(ext.getSupplyClaimedByWallet(0, receiver), 10);

        vm.roll(100);
        ext.setClaimConditions(0, conditions[0], true);
        assertEq(ext.getSupplyClaimedByWallet(0, receiver), 0);

        vm.prank(receiver, receiver);
        ext.claim(receiver, 0, 10, address(0), 0, alp, "");
        assertEq(ext.getSupplyClaimedByWallet(0, receiver), 10);
    }

    /**
     *  note: Testing state; unique condition Id for every token.
     */
    function test_state_claimCondition_uniqueConditionId() public {
        ext.setCondition(true);
        vm.warp(1);

        address receiver = address(0x123);
        address claimer1 = address(0x345);
        bytes32[] memory proofs = new bytes32[](0);
        uint256 _tokenId = 0;

        MyDropSinglePhase1155.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase1155.ClaimCondition[] memory conditions = new MyDropSinglePhase1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(_tokenId, conditions[0], false);

        vm.prank(claimer1, claimer1);
        ext.claim(receiver, _tokenId, 100, address(0), 0, alp, "");

        assertEq(ext.getSupplyClaimedByWallet(_tokenId, claimer1), 100);

        // supply claimed for other tokenIds should be 0
        assertEq(ext.getSupplyClaimedByWallet(1, claimer1), 0);
        assertEq(ext.getSupplyClaimedByWallet(2, claimer1), 0);
    }
}
