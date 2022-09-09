// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC20Claimable.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract CheckTest is BaseTest {
    AirdropERC20Claimable internal drop;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20Claimable(getContract("AirdropERC20Claimable"));

        erc20.mint(address(airdropTokenOwner), 10_000 ether);
        airdropTokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
             Unit tests: `claim` -- for allowlisted claimers
    //////////////////////////////////////////////////////////////*/

    // function test_state_claim_allowlistedClaimer() public {
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     inputs[2] = Strings.toString(5);

    //     bytes memory result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     vm.warp(1);

    //     address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
    //     uint256 quantity = 2;

    //     uint256 _availableAmount = drop.availableAmount();

    //     vm.prank(receiver);
    //     drop.claim(receiver, quantity, proofs, 5);

    //     assertEq(erc20.balanceOf(receiver), quantity);
    //     assertEq(erc20.balanceOf(address(airdropTokenOwner)), _availableAmount - quantity);
    //     assertEq(drop.supplyClaimedByWallet(receiver), quantity);
    //     assertEq(drop.availableAmount(), _availableAmount - quantity);
    // }

    // function test_revert_claim_notInAllowlist() public {
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     inputs[2] = Strings.toString(4); // generate proof with incorrect amount

    //     bytes memory result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     vm.warp(1);

    //     address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
    //     uint256 quantity = 2;

    //     vm.prank(receiver);
    //     vm.expectRevert("not in whitelist.");
    //     drop.claim(receiver, quantity, proofs, 4);
    // }

    // function test_state_claim_allowlistedClaimer_proofClaimed() public {
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     inputs[2] = Strings.toString(5);

    //     bytes memory result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     vm.warp(1);

    //     address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
    //     uint256 quantity = 2;

    //     vm.prank(receiver);
    //     drop.claim(receiver, quantity, proofs, 5);

    //     quantity = 3;

    //     vm.prank(receiver);
    //     drop.claim(receiver, quantity, proofs, 5);

    //     vm.prank(receiver);
    //     vm.expectRevert("proof claimed.");
    //     drop.claim(receiver, quantity, proofs, 5);
    // }

    // function test_state_claim_allowlistedClaimer_invalidQuantity() public {
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     inputs[2] = Strings.toString(5);

    //     bytes memory result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     vm.warp(1);

    //     address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
    //     uint256 quantity = 6;

    //     vm.prank(receiver);
    //     vm.expectRevert("invalid quantity.");
    //     drop.claim(receiver, quantity, proofs, 5);
    // }

    // function test_state_claim_allowlistedClaimer_airdropExpired() public {
    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     inputs[2] = Strings.toString(5);

    //     bytes memory result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     vm.warp(1001);

    //     address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
    //     uint256 quantity = 5;

    //     vm.prank(receiver);
    //     vm.expectRevert("airdrop expired.");
    //     drop.claim(receiver, quantity, proofs, 5);
    // }

    /*///////////////////////////////////////////////////////////////
             Unit tests: `claim` -- for open claiming
    //////////////////////////////////////////////////////////////*/

    // function test_state_claim_nonAllowlistedClaimer() public {

    //     address receiver = address(0x123);
    //     uint256 quantity = 1;
    //     bytes32[] memory proofs;

    //     uint256 _availableAmount = drop.availableAmount();

    //     vm.prank(receiver);
    //     drop.claim(receiver, quantity, proofs, 0);

    //     assertEq(erc20.balanceOf(receiver), quantity);
    //     assertEq(erc20.balanceOf(address(airdropTokenOwner)), _availableAmount - quantity);
    //     assertEq(drop.supplyClaimedByWallet(receiver), quantity);
    //     assertEq(drop.availableAmount(), _availableAmount - quantity);
    // }

    // function test_revert_claim_nonAllowlistedClaimer_invalidQuantity() public {

    //     address receiver = address(0x123);
    //     uint256 quantity = 2;
    //     bytes32[] memory proofs;

    //     vm.prank(receiver);
    //     vm.expectRevert("invalid quantity.");
    //     drop.claim(receiver, quantity, proofs, 0);
    // }

    // function test_revert_claim_nonAllowlistedClaimer_exceedsAvailable() public {

    //     uint256 _availableAmount = drop.availableAmount();
    //     bytes32[] memory proofs;

    //     uint256 i = 0;
    //     for(; i < _availableAmount; i++) {
    //         address receiver = getActor(uint160(i));
    //         vm.prank(receiver);
    //         drop.claim(receiver, 1, proofs, 0);
    //     }

    //     address receiver = getActor(uint160(i));
    //     vm.prank(receiver);
    //     vm.expectRevert("exceeds available tokens.");
    //     drop.claim(receiver, 1, proofs, 0);
    // }
}
