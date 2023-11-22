// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/prebuilts/unaudited/airdrop/AirdropERC721Claimable.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { BaseTest } from "../utils/BaseTest.sol";
import { Strings } from "contracts/lib/Strings.sol";

contract AirdropERC721ClaimableTest is BaseTest {
    address public implementation;
    AirdropERC721Claimable internal drop;

    function setUp() public override {
        super.setUp();

        address implementation = address(new AirdropERC721Claimable());

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        drop = AirdropERC721Claimable(
            address(
                new TWProxy(
                    implementation,
                    abi.encodeCall(
                        AirdropERC721Claimable.initialize,
                        (
                            forwarders(),
                            address(airdropTokenOwner),
                            address(erc721),
                            _airdropTokenIdsERC721,
                            1000,
                            1,
                            _airdropMerkleRootERC721
                        )
                    )
                )
            )
        );

        erc721.mint(address(airdropTokenOwner), 1000);
        airdropTokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);
    }

    //     /*///////////////////////////////////////////////////////////////
    //              Unit tests: `claim` -- for allowlisted claimers
    //     //////////////////////////////////////////////////////////////*/

    function test_state_claim_allowlistedClaimer() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 2;

        uint256 _availableAmount = drop.availableAmount();
        uint256 _nextIndex = drop.nextIndex();

        vm.prank(receiver);
        drop.claim(receiver, quantity, proofs, 5);

        for (uint256 i = 0; i < quantity; i++) {
            assertEq(erc721.ownerOf(i), receiver);
        }
        assertEq(drop.nextIndex(), _nextIndex + quantity);
        assertEq(drop.supplyClaimedByWallet(receiver), quantity);
        assertEq(drop.availableAmount(), _availableAmount - quantity);
    }

    function test_revert_claim_notInAllowlist() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(4)); // generate proof with incorrect amount

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 2;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, proofs, 4);
    }

    function test_revert_claim_allowlistedClaimer_proofClaimed() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 2;

        uint256 _availableAmount = drop.availableAmount();
        uint256 _nextIndex = drop.nextIndex();

        vm.prank(receiver);
        drop.claim(receiver, quantity, proofs, 5);

        for (uint256 i = 0; i < quantity; i++) {
            assertEq(erc721.ownerOf(i), receiver);
        }
        assertEq(drop.nextIndex(), _nextIndex + quantity);
        assertEq(drop.supplyClaimedByWallet(receiver), quantity);
        assertEq(drop.availableAmount(), _availableAmount - quantity);

        quantity = 3;

        vm.prank(receiver);
        drop.claim(receiver, quantity, proofs, 5);

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, proofs, 5);
    }

    function test_state_claim_allowlistedClaimer_invalidQuantity() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 6;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, proofs, 5);
    }

    function test_state_claim_allowlistedClaimer_airdropExpired() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1001);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 5;

        vm.prank(receiver);
        vm.expectRevert("airdrop expired.");
        drop.claim(receiver, quantity, proofs, 5);
    }

    /*///////////////////////////////////////////////////////////////
                 Unit tests: `claim` -- for open claiming
    //////////////////////////////////////////////////////////////*/

    function test_state_claim_nonAllowlistedClaimer() public {
        address receiver = address(0x123);
        uint256 quantity = 1;
        bytes32[] memory proofs;

        uint256 _availableAmount = drop.availableAmount();
        uint256 _nextIndex = drop.nextIndex();

        vm.prank(receiver);
        drop.claim(receiver, quantity, proofs, 0);

        assertEq(erc721.ownerOf(0), receiver);
        assertEq(drop.nextIndex(), _nextIndex + quantity);
        assertEq(drop.supplyClaimedByWallet(receiver), quantity);
        assertEq(drop.availableAmount(), _availableAmount - quantity);
    }

    function test_revert_claim_nonAllowlistedClaimer_invalidQuantity() public {
        address receiver = address(0x123);
        uint256 quantity = 2;
        bytes32[] memory proofs;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, proofs, 0);
    }

    function test_revert_claim_nonAllowlistedClaimer_exceedsAvailable() public {
        uint256 _availableAmount = drop.availableAmount();
        bytes32[] memory proofs;

        uint256 i = 0;
        for (; i < _availableAmount; i++) {
            address receiver = getActor(uint160(i));
            vm.prank(receiver);
            drop.claim(receiver, 1, proofs, 0);
        }

        address receiver = getActor(uint160(i));
        vm.prank(receiver);
        vm.expectRevert("exceeds available tokens.");
        drop.claim(receiver, 1, proofs, 0);
    }
}
