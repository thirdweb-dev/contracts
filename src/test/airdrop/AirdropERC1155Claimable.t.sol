// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/prebuilts/unaudited/airdrop/AirdropERC1155Claimable.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { BaseTest } from "../utils/BaseTest.sol";
import { Strings } from "contracts/lib/Strings.sol";

contract AirdropERC1155ClaimableTest is BaseTest {
    address public implementation;
    AirdropERC1155Claimable internal drop;

    function setUp() public override {
        super.setUp();

        address implementation = address(new AirdropERC1155Claimable());

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        drop = AirdropERC1155Claimable(
            address(
                new TWProxy(
                    implementation,
                    abi.encodeCall(
                        AirdropERC1155Claimable.initialize,
                        (
                            forwarders(),
                            address(airdropTokenOwner),
                            address(erc1155),
                            _airdropTokenIdsERC1155,
                            _airdropAmountsERC1155,
                            1000,
                            _airdropWalletClaimCountERC1155,
                            _airdropMerkleRootERC1155
                        )
                    )
                )
            )
        );

        erc1155.mint(address(airdropTokenOwner), 0, 100);
        erc1155.mint(address(airdropTokenOwner), 1, 100);
        erc1155.mint(address(airdropTokenOwner), 2, 100);
        erc1155.mint(address(airdropTokenOwner), 3, 100);
        erc1155.mint(address(airdropTokenOwner), 4, 100);

        airdropTokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), true);
    }

    /*///////////////////////////////////////////////////////////////
             Unit tests: `claim` -- for allowlisted claimers
    //////////////////////////////////////////////////////////////*/

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
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(4)); // generate proof with incorrect amount

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 2;
        uint256 id = 0;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, id, proofs, 5);
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
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        uint256 quantity = 6;
        uint256 id = 0;

        vm.prank(receiver);
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, quantity, id, proofs, 5);
    }

    function test_revert_claim_allowlistedClaimer_airdropExpired() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "src/test/scripts/getProofAirdrop.ts";
        inputs[2] = Strings.toString(uint256(5));

        bytes memory result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1001);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
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
