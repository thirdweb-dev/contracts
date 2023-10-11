// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/prebuilts/drop/DropERC721.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract HarnessDropERC721 is DropERC721 {
    function transferTokensOnClaim(address _to, uint256 _quantityToClaim) public payable {
        _transferTokensOnClaim(_to, _quantityToClaim);
    }
}

contract DropERC721Test_transferTokensOnClaim is BaseTest {
    using StringsUpgradeable for uint256;

    address public dropImp;
    HarnessDropERC721 public proxy;

    address private transferTokens_saleRecipient = address(0x010);
    address private transferTokens_royaltyRecipient = address(0x011);
    uint128 private transferTokens_royaltyBps = 1000;
    uint128 private transferTokens_platformFeeBps = 1000;
    address private transferTokens_platformFeeRecipient = address(0x012);
    uint256 private transferTokens_quantityToClaim = 1;
    address private transferTokens_receiver;

    ERC20 private nonReceiver;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC721.initialize,
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

        dropImp = address(new HarnessDropERC721());
        proxy = HarnessDropERC721(address(new TWProxy(dropImp, initializeData)));

        nonReceiver = new ERC20("", "");
    }

    modifier transferToEOA() {
        transferTokens_receiver = address(0x111);
        _;
    }

    modifier transferToNonReceiver() {
        transferTokens_receiver = address(nonReceiver);
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    function test_revert_transferToNonReceiver() public transferToNonReceiver {
        vm.expectRevert(IERC721AUpgradeable.TransferToNonERC721ReceiverImplementer.selector);
        proxy.transferTokensOnClaim(transferTokens_receiver, 1);
    }

    function test_transferToEOA() public transferToEOA {
        uint256 eoaBalanceBefore = proxy.balanceOf(transferTokens_receiver);
        uint256 supplyBefore = proxy.totalSupply();
        proxy.transferTokensOnClaim(transferTokens_receiver, 1);
        assertEq(proxy.totalSupply(), supplyBefore + 1);
        assertEq(proxy.balanceOf(transferTokens_receiver), eoaBalanceBefore + 1);
    }
}
