// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { OpenEditionERC721, IERC721AUpgradeable } from "contracts/prebuilts/open-edition/OpenEditionERC721.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract OpenEditionERC721Harness is OpenEditionERC721 {
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

contract OpenEditionERC721Test_transferTokensOnClaim is BaseTest {
    OpenEditionERC721Harness public openEdition;

    MockERC721NotReceiver private notReceiver;
    MockERC721Receiver private receiver;

    address private openEditionImpl;

    function setUp() public override {
        super.setUp();
        openEditionImpl = address(new OpenEditionERC721Harness());
        vm.prank(deployer);
        openEdition = OpenEditionERC721Harness(
            address(
                new TWProxy(
                    openEditionImpl,
                    abi.encodeCall(
                        OpenEditionERC721.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps
                        )
                    )
                )
            )
        );

        receiver = new MockERC721Receiver();
        notReceiver = new MockERC721NotReceiver();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc
    //////////////////////////////////////////////////////////////*/

    function test_revert_TransferToNonReceiverContract() public {
        vm.expectRevert(IERC721AUpgradeable.TransferToNonERC721ReceiverImplementer.selector);
        openEdition.transferTokensOnClaim(address(notReceiver), 1);
    }

    function test_state_transferToReceiverContract() public {
        uint256 receiverBalanceBefore = openEdition.balanceOf(address(receiver));
        uint256 nextTokenToMintBefore = openEdition.nextTokenIdToMint();

        openEdition.transferTokensOnClaim(address(receiver), 1);

        uint256 receiverBalanceAfter = openEdition.balanceOf(address(receiver));
        uint256 nextTokenToMintAfter = openEdition.nextTokenIdToMint();

        assertEq(receiverBalanceAfter, receiverBalanceBefore + 1);
        assertEq(nextTokenToMintAfter, nextTokenToMintBefore + 1);
    }

    function test_state_transferToEOA() public {
        address to = address(0x01);
        uint256 receiverBalanceBefore = openEdition.balanceOf(to);
        uint256 nextTokenToMintBefore = openEdition.nextTokenIdToMint();

        openEdition.transferTokensOnClaim(to, 1);

        uint256 receiverBalanceAfter = openEdition.balanceOf(to);
        uint256 nextTokenToMintAfter = openEdition.nextTokenIdToMint();

        assertEq(receiverBalanceAfter, receiverBalanceBefore + 1);
        assertEq(nextTokenToMintAfter, nextTokenToMintBefore + 1);
    }
}
