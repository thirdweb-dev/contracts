// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ERC1155Drop } from "contracts/base/ERC1155Drop.sol";

import "contracts/lib/TWStrings.sol";

contract ERC1155DropTest is DSTest, Test {
    using TWStrings for uint256;

    // Target contract
    ERC1155Drop internal base;

    // Signers
    uint256 internal adminPkey;
    uint256 internal nftHolderPkey;

    address internal admin;
    address internal nftHolder;
    address internal saleRecipient;

    ERC1155Drop.ClaimCondition condition;
    ERC1155Drop.AllowlistProof allowlistProof;

    uint256 internal targetTokenId;

    function setUp() public {
        adminPkey = 123;
        nftHolderPkey = 456;

        admin = vm.addr(adminPkey);
        nftHolder = vm.addr(nftHolderPkey);
        saleRecipient = address(0x8910);

        vm.deal(nftHolder, 100 ether);

        vm.prank(admin);
        base = new ERC1155Drop("name", "symbol", admin, 0, saleRecipient);

        targetTokenId = base.nextTokenIdToMint();

        vm.prank(admin);
        base.lazyMint(1, "ipfs://", "");
    }

    function test_state_setClaimConditions() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        (
            ,
            uint256 maxClaimable,
            ,
            uint256 quantityLimitPerTransaction,
            uint256 waitTimeInSecondsBetweenClaims,
            ,
            ,
            address currency
        ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimable, 100);
        assertEq(quantityLimitPerTransaction, 5);
        assertEq(waitTimeInSecondsBetweenClaims, 100);
        assertEq(currency, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function test_state_setClaimConditions_resetEligibility() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, false);

        vm.prank(nftHolder, nftHolder);
        base.claim(nftHolder, targetTokenId, 1, condition.currency, condition.pricePerToken, allowlistProof, "");

        (, , uint256 supplyClaimedBefore, , , , , ) = base.claimCondition(targetTokenId);
        assertEq(supplyClaimedBefore, 1);

        (, uint256 claimTimestampBefore) = base.getClaimTimestamp(targetTokenId, nftHolder);
        assertEq(claimTimestampBefore, block.timestamp + claimTimestampBefore - 1);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, false);

        (, , uint256 supplyClaimedAfter, , , , , ) = base.claimCondition(targetTokenId);
        assertEq(supplyClaimedBefore, supplyClaimedAfter);

        (, uint256 claimTimestampAfter) = base.getClaimTimestamp(targetTokenId, nftHolder);
        assertEq(claimTimestampBefore, claimTimestampAfter);
    }

    function test_revert_setClaimConditions_unauthorizedCaller() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(nftHolder);
        vm.expectRevert("Not authorized");
        base.setClaimConditions(targetTokenId, condition, true);
    }

    function test_revert_setClaimConditions_supplyClaimedAlready() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 100;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, false);

        vm.prank(nftHolder, nftHolder);
        base.claim(
            nftHolder,
            targetTokenId,
            condition.quantityLimitPerTransaction,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );

        condition.maxClaimableSupply = 50;

        vm.prank(admin);
        vm.expectRevert("max supply claimed");
        base.setClaimConditions(targetTokenId, condition, false);
    }

    function test_state_claim() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = 5;
        vm.prank(nftHolder, nftHolder);
        base.claim(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );

        (, , uint256 supplyClaimed, , , , , ) = base.claimCondition(targetTokenId);
        assertEq(supplyClaimed, quantityToClaim);

        (, uint256 nextClaimTimestamp) = base.getClaimTimestamp(targetTokenId, nftHolder);
        assertEq(nextClaimTimestamp, block.timestamp + nextClaimTimestamp - 1);

        assertEq(base.balanceOf(nftHolder, targetTokenId), quantityToClaim);
        assertEq(base.totalSupply(targetTokenId), quantityToClaim);
    }

    function test_state_claim_withPrice() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = 5;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        uint256 saleRecipientBalBefore = saleRecipient.balance;

        vm.prank(nftHolder, nftHolder);
        base.claim{ value: totalPrice }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );

        assertEq(saleRecipient.balance, saleRecipientBalBefore + totalPrice);
    }

    function test_state_claim_withAllowlist() public {
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "1";

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address claimer = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);

        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = root;
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        allowlistProof.proof = proofs;
        allowlistProof.maxQuantityInAllowlist = 1;

        uint256 quantityToClaim = allowlistProof.maxQuantityInAllowlist;

        vm.prank(claimer, claimer);
        base.claim(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );

        (, , uint256 supplyClaimed, , , , , ) = base.claimCondition(targetTokenId);
        assertEq(supplyClaimed, quantityToClaim);

        (, uint256 nextClaimTimestamp) = base.getClaimTimestamp(targetTokenId, nftHolder);
        assertEq(nextClaimTimestamp, block.timestamp + nextClaimTimestamp - 1);

        assertEq(base.balanceOf(nftHolder, targetTokenId), quantityToClaim);
        assertEq(base.totalSupply(targetTokenId), quantityToClaim);
    }

    function test_revert_claim_notInAllowlist() public {
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "1";

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = root;
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        allowlistProof.proof = proofs;
        allowlistProof.maxQuantityInAllowlist = 1;

        uint256 quantityToClaim = allowlistProof.maxQuantityInAllowlist;

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("not in allowlist");
        base.claim(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_allowlistSpotClaimed() public {
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "1";

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address claimer = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);

        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = root;
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        allowlistProof.proof = proofs;
        allowlistProof.maxQuantityInAllowlist = 1;

        uint256 quantityToClaim = allowlistProof.maxQuantityInAllowlist;

        vm.prank(claimer, claimer);
        base.claim(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );

        (, , uint256 supplyClaimed, , , , , ) = base.claimCondition(targetTokenId);
        assertEq(supplyClaimed, quantityToClaim);

        (, uint256 nextClaimTimestamp) = base.getClaimTimestamp(targetTokenId, nftHolder);
        assertEq(nextClaimTimestamp, block.timestamp + nextClaimTimestamp - 1);

        assertEq(base.balanceOf(nftHolder, targetTokenId), quantityToClaim);
        assertEq(base.totalSupply(targetTokenId), quantityToClaim);

        vm.prank(claimer, claimer);
        vm.expectRevert("proof claimed");
        base.claim(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_invalidQtyProof() public {
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "1";

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address claimer = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);

        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = root;
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        allowlistProof.proof = proofs;
        allowlistProof.maxQuantityInAllowlist = 1;

        uint256 quantityToClaim = allowlistProof.maxQuantityInAllowlist + 1;

        vm.prank(claimer, claimer);
        vm.expectRevert("Invalid qty proof");
        base.claim(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_invalidPrice() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = 5;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("Invalid price or currency");
        base.claim{ value: totalPrice - 1 }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            0,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_insufficientPrice() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = 5;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("Must send total price.");
        base.claim{ value: totalPrice - 1 }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_invalidCurrency() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = address(0x123);

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = 5;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("Invalid price or currency");
        base.claim{ value: totalPrice }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_invalidQuantity() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = condition.quantityLimitPerTransaction + 1;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("Invalid quantity");
        base.claim{ value: totalPrice }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_exceedsMaxSupply() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 101;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = condition.quantityLimitPerTransaction;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("exceeds max supply");
        base.claim{ value: totalPrice }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }

    function test_revert_claim_cantClaimYet() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerTransaction = 5;
        condition.waitTimeInSecondsBetweenClaims = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = condition.quantityLimitPerTransaction;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        vm.prank(nftHolder, nftHolder);
        base.claim{ value: totalPrice }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("cant claim yet");
        base.claim{ value: totalPrice }(
            nftHolder,
            targetTokenId,
            quantityToClaim,
            condition.currency,
            condition.pricePerToken,
            allowlistProof,
            ""
        );
    }
}
