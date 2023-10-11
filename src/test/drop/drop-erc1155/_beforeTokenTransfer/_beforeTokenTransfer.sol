// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC1155 is DropERC1155 {
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

contract DropERC1155Test_beforeTokenTransfer is BaseTest {
    address private beforeTransfer_from = address(0x01);
    address private beforeTransfer_to = address(0x01);
    uint256[] private beforeTransfer_ids;
    uint256[] private beforeTransfer_amounts;
    bytes private beforeTransfer_data;

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

        beforeTransfer_ids = new uint256[](1);
        beforeTransfer_ids[0] = 0;
        beforeTransfer_amounts = new uint256[](1);
        beforeTransfer_amounts[0] = 1;
        beforeTransfer_data = abi.encode("", "");
    }

    modifier fromAddressZero() {
        beforeTransfer_from = address(0);
        _;
    }

    modifier toAddressZero() {
        beforeTransfer_to = address(0);
        _;
    }

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_state_transferFromZero() public fromAddressZero {
        uint256 beforeTokenTotalSupply = proxy.totalSupply(0);
        proxy.beforeTokenTransfer(
            deployer,
            beforeTransfer_from,
            beforeTransfer_to,
            beforeTransfer_ids,
            beforeTransfer_amounts,
            beforeTransfer_data
        );
        uint256 afterTokenTotalSupply = proxy.totalSupply(0);
        assertEq(beforeTokenTotalSupply + beforeTransfer_amounts[0], afterTokenTotalSupply);
    }

    function test_state_tranferToZero() public toAddressZero {
        proxy.beforeTokenTransfer(
            deployer,
            beforeTransfer_to,
            beforeTransfer_from,
            beforeTransfer_ids,
            beforeTransfer_amounts,
            beforeTransfer_data
        );
        uint256 beforeTokenTotalSupply = proxy.totalSupply(0);
        proxy.beforeTokenTransfer(
            deployer,
            beforeTransfer_from,
            beforeTransfer_to,
            beforeTransfer_ids,
            beforeTransfer_amounts,
            beforeTransfer_data
        );
        uint256 afterTokenTotalSupply = proxy.totalSupply(0);
        assertEq(beforeTokenTotalSupply - beforeTransfer_amounts[0], afterTokenTotalSupply);
    }
}
