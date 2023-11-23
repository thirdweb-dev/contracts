// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC20BeforeClaim is DropERC20 {
    bytes private emptyBytes = bytes("");

    function harness_beforeClaim(uint256 quantity, AllowlistProof calldata _proof) public view {
        _beforeClaim(address(0), quantity, address(0), 0, _proof, emptyBytes);
    }
}

contract DropERC20Test_beforeClaim is BaseTest {
    address public dropImp;
    HarnessDropERC20BeforeClaim public proxy;

    uint256 private mintQty;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC20.initialize,
            (deployer, NAME, SYMBOL, CONTRACT_URI, forwarders(), saleRecipient, platformFeeRecipient, platformFeeBps)
        );

        dropImp = address(new HarnessDropERC20BeforeClaim());
        proxy = HarnessDropERC20BeforeClaim(address(new TWProxy(dropImp, initializeData)));
    }

    modifier setMaxTotalSupply() {
        vm.prank(deployer);
        proxy.setMaxTotalSupply(100);
        _;
    }

    modifier qtyExceedMaxTotalSupply() {
        mintQty = 101;
        _;
    }

    function test_revert_MaxSupplyExceeded() public setMaxTotalSupply qtyExceedMaxTotalSupply {
        DropERC20.AllowlistProof memory proof;
        vm.expectRevert("exceed max total supply.");
        proxy.harness_beforeClaim(mintQty, proof);
    }
}
