// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC1155Claimable.sol";
import { AirdropERC1155ClaimableUpdated } from "contracts/airdrop/AirdropERC1155ClaimableUpdated.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155ClaimableTest is BaseTest {
    AirdropERC1155Claimable internal drop;
    AirdropERC1155ClaimableUpdated internal newDrop;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC1155Claimable(getContract("AirdropERC1155Claimable"));

        erc1155.mint(address(airdropTokenOwner), 0, 100);
        erc1155.mint(address(airdropTokenOwner), 1, 100);
        erc1155.mint(address(airdropTokenOwner), 2, 100);
        erc1155.mint(address(airdropTokenOwner), 3, 100);
        erc1155.mint(address(airdropTokenOwner), 4, 100);

        airdropTokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), true);
    }

    /*///////////////////////////////////////////////////////////////
             Unit tests: test new airdrop state
    //////////////////////////////////////////////////////////////*/

    // function test_state_newAirdrop() public {
    //     assertEq(newDrop.tokenOwner, drop.tokenOwner);
    //     assertEq(newDrop.airdropTokenAddress, drop.airdropTokenAddress);
    //     assertEq(newDrop.tokenIds.length, drop.tokenIds.length);
    //     assertEq(newDrop.expirationTimestamp, drop.expirationTimestamp);

    //     for (uint256 i = 0; i < drop.tokenIds.length; i++) {
    //         assertEq(newDrop.availableAmount(i), drop.availableAmount(i));
    //     }
    // }

    function test_state_newAirdrop_claims() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofForAirdrop.ts";
        inputs[2] = Strings.toString(5);

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        uint256 quantity = 2;
        uint256 id = 0;

        uint256 _availableAmount = drop.availableAmount(id);

        vm.prank(receiver);
        drop.claim(receiver, quantity, id, proofs, 5);

        assertEq(erc1155.balanceOf(receiver, id), quantity);
        assertEq(drop.supplyClaimedByWallet(id, receiver), quantity);
        assertEq(drop.availableAmount(id), _availableAmount - quantity);

        // deploy and initialize new airdrop contract
        newDrop = new AirdropERC1155ClaimableUpdated(address(drop));
        uint256[] memory emptyArray = new uint256[](0);
        bytes32[] memory emptyBytes = new bytes32[](0);
        newDrop.initialize(
            deployer,
            forwarders(),
            address(0),
            address(0),
            _airdropTokenIdsERC1155,
            emptyArray,
            0,
            emptyArray,
            emptyBytes
        );
        airdropTokenOwner.setApprovalForAllERC1155(address(erc1155), address(newDrop), true);

        assertEq(newDrop.tokenOwner(), drop.tokenOwner());
        assertEq(newDrop.airdropTokenAddress(), drop.airdropTokenAddress());
        // assertEq(newDrop.tokenIds.length, drop.tokenIds.length);
        assertEq(newDrop.expirationTimestamp(), drop.expirationTimestamp());

        for (uint256 i = 0; i < _airdropTokenIdsERC1155.length; i++) {
            assertEq(newDrop.availableAmount(i), drop.availableAmount(i));
            assertEq(newDrop.merkleRoot(i), drop.merkleRoot(i));
        }

        assertEq(newDrop.supplyClaimedByWallet(id, receiver), 0);
        assertEq(newDrop.availableAmount(id), _availableAmount - quantity);

        // claim on the new contract
        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        newDrop.claim(receiver, 4, id, proofs, 5);
    }

    /*///////////////////////////////////////////////////////////////
             Unit tests: `claim` -- for allowlisted claimers
    //////////////////////////////////////////////////////////////*/

    function test_state_claim_allowlistedClaimer() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofForAirdrop.ts";
        inputs[2] = Strings.toString(5);

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        uint256 quantity = 2;
        uint256 id = 0;

        uint256 _availableAmount = drop.availableAmount(id);

        vm.prank(receiver);
        drop.claim(receiver, quantity, id, proofs, 5);

        assertEq(erc1155.balanceOf(receiver, id), quantity);
        assertEq(drop.supplyClaimedByWallet(id, receiver), quantity);
        assertEq(drop.availableAmount(id), _availableAmount - quantity);
    }

    function test_revert_claim_notInAllowlist_invalidQty() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofForAirdrop.ts";
        inputs[2] = Strings.toString(4); // generate proof with incorrect amount

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        uint256 quantity = 2;
        uint256 id = 0;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, id, proofs, 5);
    }

    function test_revert_claim_allowlistedClaimer_proofClaimed() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofForAirdrop.ts";
        inputs[2] = Strings.toString(5);

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        uint256 quantity = 2;
        uint256 id = 0;

        vm.prank(receiver);
        drop.claim(receiver, quantity, id, proofs, 5);

        quantity = 3;

        vm.prank(receiver);
        drop.claim(receiver, quantity, id, proofs, 5);

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, id, proofs, 5);
    }

    function test_state_claim_allowlistedClaimer_invalidQuantity() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofForAirdrop.ts";
        inputs[2] = Strings.toString(5);

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        uint256 quantity = 6;
        uint256 id = 0;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, id, proofs, 5);
    }

    function test_revert_claim_allowlistedClaimer_airdropExpired() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofForAirdrop.ts";
        inputs[2] = Strings.toString(5);

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1001);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        uint256 quantity = 5;
        uint256 id = 0;

        vm.prank(receiver);
        vm.expectRevert("airdrop expired.");
        drop.claim(receiver, quantity, id, proofs, 5);
    }

    /*///////////////////////////////////////////////////////////////
             Unit tests: `claim` -- for open claiming
    //////////////////////////////////////////////////////////////*/

    function test_state_claim_nonAllowlistedClaimer() public {
        address receiver = address(0x123);
        uint256 quantity = 1;
        bytes32[] memory proofs;
        uint256 id = 0;

        uint256 _availableAmount = drop.availableAmount(id);

        vm.prank(receiver);
        drop.claim(receiver, quantity, id, proofs, 0);

        assertEq(erc1155.balanceOf(receiver, id), quantity);
        assertEq(drop.supplyClaimedByWallet(id, receiver), quantity);
        assertEq(drop.availableAmount(id), _availableAmount - quantity);
    }

    function test_state_claim_nonAllowlistedClaimer_nonZeroQuantity() public {
        address receiver = address(0x123);
        uint256 quantity = 5;
        bytes32[] memory proofs;
        uint256 id = 0;

        uint256 _availableAmount = drop.availableAmount(id);

        vm.prank(receiver);
        drop.claim(receiver, quantity, id, proofs, 1);

        assertEq(erc1155.balanceOf(receiver, id), 0);
        assertEq(drop.supplyClaimedByWallet(id, receiver), quantity);
        assertEq(drop.availableAmount(id), _availableAmount - quantity);

        vm.expectRevert("invalid quantity.");
        vm.prank(receiver);
        drop.claim(receiver, quantity, id, proofs, 1);
    }

    function test_revert_claim_nonAllowlistedClaimer_invalidQuantity() public {
        address receiver = address(0x123);
        uint256 quantity = 2;
        bytes32[] memory proofs;
        uint256 id = 0;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, id, proofs, 0);
    }

    function test_revert_claim_nonAllowlistedClaimer_exceedsAvailable() public {
        uint256 id = 0;
        uint256 _availableAmount = drop.availableAmount(id);
        bytes32[] memory proofs;

        uint256 i = 0;
        for (; i < _availableAmount; i++) {
            address receiver = getActor(uint160(i));
            vm.prank(receiver);
            drop.claim(receiver, 1, id, proofs, 0);
        }

        address receiver = getActor(uint160(i));
        vm.prank(receiver);
        vm.expectRevert("exceeds available tokens.");
        drop.claim(receiver, 1, id, proofs, 0);
    }
}
