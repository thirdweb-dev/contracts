// <ai_context>
// Unit tests for the internal _transferTokensOnClaim function in DropERC721FlatFee contract.
// Tests minting to EOA or receiver contracts.
// </ai_context>

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721FlatFee, IERC721AUpgradeable } from "contracts/prebuilts/drop/DropERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract DropERC721FlatFeeHarness is DropERC721FlatFee {
    function transferTokensOnClaim(address _to, uint256 quantityBeingClaimed) public {
        _transferTokensOnClaim(_to, quantityBeingClaimed);
    }
}

contract MockERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract MockERC721NotReceiver {}

contract DropERC721FlatFeeTest_transferTokensOnClaim is BaseTest {
    DropERC721FlatFeeHarness public drop;

    MockERC721NotReceiver private notReceiver;
    MockERC721Receiver private receiver;

    address private dropImpl;

    function setUp() public override {
        super.setUp();
        dropImpl = address(new DropERC721FlatFeeHarness());
        vm.prank(deployer);
        drop = DropERC721FlatFeeHarness(
            address(
                new TWProxy(
                    dropImpl,
                    abi.encodeCall(
                        DropERC721FlatFee.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps,
                            platformFeeBps,
                            platformFeeRecipient
                        )
                    )
                )
            )
        );
        // Set to flat fee mode
        vm.prank(deployer);
        drop.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);
        vm.prank(deployer);
        drop.setFlatPlatformFeeInfo(platformFeeRecipient, 0.1 ether);

        receiver = new MockERC721Receiver();
        notReceiver = new MockERC721NotReceiver();
    }

    function test_revert_TransferToNonReceiverContract() public {
        vm.expectRevert(IERC721AUpgradeable.TransferToNonERC721ReceiverImplementer.selector);
        drop.transferTokensOnClaim(address(notReceiver), 1);
    }

    function test_state_transferToReceiverContract() public {
        uint256 receiverBalanceBefore = drop.balanceOf(address(receiver));
        uint256 nextTokenToMintBefore = drop.nextTokenIdToClaim();

        drop.transferTokensOnClaim(address(receiver), 1);

        uint256 receiverBalanceAfter = drop.balanceOf(address(receiver));
        uint256 nextTokenToMintAfter = drop.nextTokenIdToClaim();

        assertEq(receiverBalanceAfter, receiverBalanceBefore + 1);
        assertEq(nextTokenToMintAfter, nextTokenToMintBefore + 1);
    }

    function test_state_transferToEOA() public {
        address to = address(0x01);
        uint256 receiverBalanceBefore = drop.balanceOf(to);
        uint256 nextTokenToMintBefore = drop.nextTokenIdToClaim();

        drop.transferTokensOnClaim(to, 1);

        uint256 receiverBalanceAfter = drop.balanceOf(to);
        uint256 nextTokenToMintAfter = drop.nextTokenIdToClaim();

        assertEq(receiverBalanceAfter, receiverBalanceBefore + 1);
        assertEq(nextTokenToMintAfter, nextTokenToMintBefore + 1);
    }
}