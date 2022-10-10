// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

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

    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        override
        returns (uint256 startTokenId)
    {}
}

contract ExtensionDropSinglePhase is DSTest, Test {
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
     *  note: Testing revert condition; not allowed to claim again before wait time is over.
     */
    function test_revert_claimCondition_waitTimeInSecondsBetweenClaims() public {
        ext.setCondition(true);
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        bytes32[] memory proofs = new bytes32[](0);

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        ext.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        ext.claim(receiver, 1, address(0), 0, alp, "");

        vm.expectRevert("cant claim yet");
        vm.prank(claimer, claimer);
        ext.claim(receiver, 1, address(0), 0, alp, "");
    }

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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        ext.setClaimConditions(conditions[0], false);

        vm.prank(claimer1, claimer1);
        ext.claim(receiver, 100, address(0), 0, alp, "");

        vm.expectRevert("exceeds max supply");
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
        alp.maxQuantityInAllowlist = x;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        ext.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        vm.expectRevert("Invalid quantity");
        ext.claim(receiver, 101, address(0), 0, alp, "");

        ext.setClaimConditions(conditions[0], true);

        vm.prank(claimer, claimer);
        vm.expectRevert("Invalid quantity");
        ext.claim(receiver, 101, address(0), 0, alp, "");
    }

    /**
     *  note: Testing revert condition; can't claim if not in whitelist.
     */
    function test_revert_claimCondition_merkleProof() public {
        ext.setCondition(true);
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "1";

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address claimer = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.maxQuantityInAllowlist = 1;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;
        conditions[0].merkleRoot = root;

        ext.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        ext.claim(claimer, 1, address(0), 0, alp, "");

        vm.prank(address(4), address(4));
        vm.expectRevert("not in allowlist");
        ext.claim(address(4), 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing state changes; reset eligibility of claim conditions and claiming again for same condition id.
     */
    function test_state_claimCondition_resetEligibility_waitTimeInSecondsBetweenClaims() public {
        ext.setCondition(true);
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        bytes32[] memory proofs = new bytes32[](0);

        MyDropSinglePhase.AllowlistProof memory alp;
        alp.proof = proofs;

        MyDropSinglePhase.ClaimCondition[] memory conditions = new MyDropSinglePhase.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        ext.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        ext.claim(receiver, 1, address(0), 0, alp, "");

        ext.setClaimConditions(conditions[0], true);

        vm.prank(claimer, claimer);
        ext.claim(receiver, 1, address(0), 0, alp, "");
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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        ext.setClaimConditions(conditions[0], false);

        vm.startPrank(claimer, claimer);

        vm.expectEmit(true, true, true, true);
        emit TokensClaimed(claimer, receiver, 0, 1);

        ext.claim(receiver, 1, address(0), 0, alp, "");
    }
}
