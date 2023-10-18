// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";

contract DropERC1155Test_burnBatch is BaseTest {
    DropERC1155 public drop;

    address private unauthorized = address(0x999);
    address private account;
    uint256[] private ids;
    uint256[] private values;

    address private receiver;
    bytes private emptyEncodedBytes = abi.encode("", "");

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));

        ids = new uint256[](1);
        values = new uint256[](1);
        ids[0] = 0;
        values[0] = 1;
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerNotApproved() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerOwner() {
        receiver = getActor(0);
        vm.startPrank(receiver);
        _;
    }

    modifier callerApproved() {
        receiver = getActor(0);
        vm.prank(receiver);
        drop.setApprovalForAll(deployer, true);
        vm.startPrank(deployer);
        _;
    }

    modifier IdValueMismatch() {
        values = new uint256[](2);
        values[0] = 1;
        values[1] = 1;
        _;
    }

    modifier tokenClaimed() {
        vm.warp(1);

        uint256 _tokenId = 0;
        receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, _tokenId, 1, address(0), 0, alp, "");

        _;
    }

    function test_revert_callerNotApproved() public tokenClaimed callerNotApproved {
        vm.expectRevert("ERC1155: caller is not owner nor approved.");
        drop.burnBatch(receiver, ids, values);
    }

    function test_state_callerApproved() public tokenClaimed callerApproved {
        uint256 beforeBalance = drop.balanceOf(receiver, ids[0]);
        drop.burnBatch(receiver, ids, values);
        uint256 afterBalance = drop.balanceOf(receiver, ids[0]);
        assertEq(beforeBalance - values[0], afterBalance);
    }

    function test_state_callerOwner() public tokenClaimed callerOwner {
        uint256 beforeBalance = drop.balanceOf(receiver, ids[0]);
        drop.burnBatch(receiver, ids, values);
        uint256 afterBalance = drop.balanceOf(receiver, ids[0]);
        assertEq(beforeBalance - values[0], afterBalance);
    }

    function test_revert_IdValueMismatch() public tokenClaimed IdValueMismatch callerOwner {
        vm.expectRevert("ERC1155: ids and amounts length mismatch");
        drop.burnBatch(receiver, ids, values);
    }

    function test_revert_balanceUnderflow() public tokenClaimed callerOwner {
        values[0] = 2;
        vm.expectRevert();
        drop.burnBatch(receiver, ids, values);
    }

    function test_event() public tokenClaimed callerOwner {
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(receiver, receiver, address(0), ids, values);
        drop.burnBatch(receiver, ids, values);
    }
}
