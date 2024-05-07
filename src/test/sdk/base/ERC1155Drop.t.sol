// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ERC1155Drop } from "contracts/base/ERC1155Drop.sol";
import { Strings } from "contracts/lib/Strings.sol";

contract ERC1155DropTest is DSTest, Test {
    using Strings for uint256;

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
        base = new ERC1155Drop(admin, "name", "symbol", admin, 0, saleRecipient);

        targetTokenId = base.nextTokenIdToMint();

        vm.prank(admin);
        base.lazyMint(1, "ipfs://", "");
    }

    function test_state_setClaimConditions() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerWallet = 5;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        (, uint256 maxClaimable, , uint256 quantityLimitPerWallet, , , address currency, ) = base.claimCondition(
            targetTokenId
        );

        assertEq(maxClaimable, 100);
        assertEq(quantityLimitPerWallet, 5);
        assertEq(currency, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function test_state_setClaimConditions_resetEligibility() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerWallet = 5;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, false);

        vm.prank(nftHolder, nftHolder);
        base.claim(nftHolder, targetTokenId, 1, condition.currency, condition.pricePerToken, allowlistProof, "");

        (, , uint256 supplyClaimedBefore, , , , , ) = base.claimCondition(targetTokenId);
        assertEq(supplyClaimedBefore, 1);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, false);

        (, , uint256 supplyClaimedAfter, , , , , ) = base.claimCondition(targetTokenId);
        assertEq(supplyClaimedBefore, supplyClaimedAfter);
    }

    function test_revert_setClaimConditions_unauthorizedCaller() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerWallet = 5;
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
        condition.quantityLimitPerWallet = 100;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, false);

        vm.prank(nftHolder, nftHolder);
        base.claim(
            nftHolder,
            targetTokenId,
            condition.quantityLimitPerWallet,
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
        condition.quantityLimitPerWallet = 5;
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

        assertEq(base.balanceOf(nftHolder, targetTokenId), quantityToClaim);
        assertEq(base.totalSupply(targetTokenId), quantityToClaim);
    }

    function test_state_claim_withPrice() public {
        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerWallet = 5;
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
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "1";
        inputs[3] = "0";
        inputs[4] = "0x0000000000000000000000000000000000000000";

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address claimer = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerWallet = 5;
        condition.merkleRoot = root;
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        allowlistProof.proof = proofs;
        allowlistProof.quantityLimitPerWallet = 1;
        allowlistProof.pricePerToken = 0;
        allowlistProof.currency = address(0);

        uint256 quantityToClaim = allowlistProof.quantityLimitPerWallet;

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

        assertEq(base.balanceOf(nftHolder, targetTokenId), quantityToClaim);
        assertEq(base.totalSupply(targetTokenId), quantityToClaim);
    }

    function test_revert_claim_invalidQtyProof() public {
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "1";
        inputs[3] = "0";
        inputs[4] = "0x0000000000000000000000000000000000000000";

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        address claimer = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

        condition.startTimestamp = block.timestamp;
        condition.maxClaimableSupply = 100;
        condition.supplyClaimed = 0;
        condition.quantityLimitPerWallet = 5;
        condition.merkleRoot = root;
        condition.pricePerToken = 0;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        allowlistProof.proof = proofs;
        allowlistProof.quantityLimitPerWallet = 1;
        allowlistProof.pricePerToken = 0;
        allowlistProof.currency = address(0);

        uint256 quantityToClaim = allowlistProof.quantityLimitPerWallet + 1;

        bytes memory errorQty = "!Qty";

        vm.prank(claimer, claimer);
        vm.expectRevert(errorQty);
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
        condition.quantityLimitPerWallet = 5;
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
        vm.expectRevert("!PriceOrCurrency");
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
        condition.quantityLimitPerWallet = 5;
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
        vm.expectRevert("Invalid msg value");
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
        condition.quantityLimitPerWallet = 5;
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
        vm.expectRevert("!PriceOrCurrency");
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
        condition.quantityLimitPerWallet = 5;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = condition.quantityLimitPerWallet + 1;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        bytes memory errorQty = "!Qty";

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert(errorQty);
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
        condition.quantityLimitPerWallet = 101;
        condition.merkleRoot = bytes32(0);
        condition.pricePerToken = 0.01 ether;
        condition.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (, uint256 maxClaimableSupplyBefore, , , , , , ) = base.claimCondition(targetTokenId);

        assertEq(maxClaimableSupplyBefore, 0);

        vm.prank(admin);
        base.setClaimConditions(targetTokenId, condition, true);

        uint256 quantityToClaim = condition.quantityLimitPerWallet;
        uint256 totalPrice = quantityToClaim * condition.pricePerToken;

        vm.prank(nftHolder, nftHolder);
        vm.expectRevert("!MaxSupply");
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
