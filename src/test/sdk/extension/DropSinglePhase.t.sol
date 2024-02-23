// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";
import { Strings } from "contracts/lib/Strings.sol";

import { DropSinglePhase } from "contracts/extension/DropSinglePhase.sol";

contract MyDropSinglePhase is DropSinglePhase {
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

    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal override returns (uint256 startTokenId) {}
}

contract ExtensionDropSinglePhase is DSTest, Test {
    using Strings for uint256;
    MyDropSinglePhase internal ext;

    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 indexed startTokenId,
        uint256 quantityClaimed
    );
    event ClaimConditionUpdated(MyDropSinglePhase.ClaimCondition condition, bool resetEligibility);

    function setUp() public {
        ext = new MyDropSinglePhase();
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

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(conditions[0], false);

        vm.prank(claimer1, claimer1);
        ext.claim(receiver, 100, address(0), 0, alp, "");

        vm.expectRevert(
            abi.encodeWithSelector(
                DropSinglePhase.DropClaimExceedMaxSupply.selector,
                conditions[0].maxClaimableSupply,
                1 + conditions[0].maxClaimableSupply
            )
        );
        vm.prank(claimer2, claimer2);
        ext.claim(receiver, 1, address(0), 0, alp, "");
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

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        vm.expectRevert(
            abi.encodeWithSelector(
                DropSinglePhase.DropClaimExceedLimit.selector,
                conditions[0].quantityLimitPerWallet,
                101
            )
        );
        ext.claim(receiver, 101, address(0), 0, alp, "");

        ext.setClaimConditions(conditions[0], true);

        vm.prank(claimer, claimer);
        vm.expectRevert(
            abi.encodeWithSelector(
                DropSinglePhase.DropClaimExceedLimit.selector,
                conditions[0].quantityLimitPerWallet,
                101
            )
        );
        ext.claim(receiver, 101, address(0), 0, alp, "");
    }

    function test_fuzz_claim_merkleProof(uint256 x) public {
        ext.setCondition(true);
        vm.assume(x > 10 && x < 500);
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = Strings.toString(x);
        inputs[3] = "0";
        inputs[4] = "0x0000000000000000000000000000000000000000";

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;
        alp.pricePerToken = 0;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

        // bytes32[] memory proofs = new bytes32[](0);

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerWallet = 1;
        conditions[0].merkleRoot = root;

        ext.setClaimConditions(conditions[0], false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        ext.claim(receiver, x - 5, address(0), 0, alp, "");
        assertEq(ext.getSupplyClaimedByWallet(receiver), x - 5);

        vm.prank(receiver, receiver);
        vm.expectRevert(
            abi.encodeWithSelector(DropSinglePhase.DropClaimExceedLimit.selector, alp.quantityLimitPerWallet, x + 1)
        );
        ext.claim(receiver, 6, address(0), 0, alp, "");

        vm.prank(receiver, receiver);
        ext.claim(receiver, 5, address(0), 0, alp, "");
        assertEq(ext.getSupplyClaimedByWallet(receiver), x);

        vm.prank(receiver, receiver);
        vm.expectRevert(
            abi.encodeWithSelector(DropSinglePhase.DropClaimExceedLimit.selector, alp.quantityLimitPerWallet, x + 5)
        );
        ext.claim(receiver, 5, address(0), 0, alp, "");
    }

    /**
     *  note: Testing event emission on setClaimConditions.
     */
    function test_event_setClaimConditions() public {
        ext.setCondition(true);
        vm.warp(1);

        bytes32[] memory proofs = new bytes32[](0);

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.expectEmit(true, true, true, true);
        emit ClaimConditionUpdated(conditions[0], false);

        ext.setClaimConditions(conditions[0], false);
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

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        ext.setClaimConditions(conditions[0], false);

        vm.startPrank(claimer, claimer);

        vm.expectEmit(true, true, true, true);
        emit TokensClaimed(claimer, receiver, 0, 1);

        ext.claim(receiver, 1, address(0), 0, alp, "");
    }
}
