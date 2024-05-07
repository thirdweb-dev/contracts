// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports

import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract HarnessDropERC1155 is DropERC1155 {
    function transferTokensOnClaimHarness(address to, uint256 _tokenId, uint256 _quantityBeingClaimed) external {
        transferTokensOnClaim(to, _tokenId, _quantityBeingClaimed);
    }
}

contract MockERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract MockERC11555NotReceiver {}

contract DropERC1155Test_transferTokensOnClaim is BaseTest {
    using Strings for uint256;
    using Strings for address;

    address private to;
    MockERC1155Receiver private receiver;
    MockERC11555NotReceiver private notReceiver;

    address public dropImp;
    HarnessDropERC1155 public proxy;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC1155.initialize,
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
        );

        dropImp = address(new HarnessDropERC1155());
        proxy = HarnessDropERC1155(address(new TWProxy(dropImp, initializeData)));

        receiver = new MockERC1155Receiver();
        notReceiver = new MockERC11555NotReceiver();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc.
    //////////////////////////////////////////////////////////////*/

    modifier toEOA() {
        to = address(0x01);
        _;
    }

    modifier toReceiever() {
        to = address(receiver);
        _;
    }

    modifier toNotReceiever() {
        to = address(notReceiver);
        _;
    }

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_revert_ContractNotERC155Receiver() public toNotReceiever {
        vm.expectRevert("ERC1155: transfer to non-ERC1155Receiver implementer");
        proxy.transferTokensOnClaimHarness(to, 0, 1);
    }

    function test_state_ContractERC1155Receiver() public toReceiever {
        uint256 beforeBalance = proxy.balanceOf(to, 0);
        proxy.transferTokensOnClaimHarness(to, 0, 1);
        uint256 afterBalance = proxy.balanceOf(to, 0);
        assertEq(beforeBalance + 1, afterBalance);
    }

    function test_state_EOAReceiver() public toEOA {
        uint256 beforeBalance = proxy.balanceOf(to, 0);
        proxy.transferTokensOnClaimHarness(to, 0, 1);
        uint256 afterBalance = proxy.balanceOf(to, 0);
        assertEq(beforeBalance + 1, afterBalance);
    }
}
