// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC1155 is DropERC1155 {
    function beforeClaim(
        uint256 _tokenId,
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata alp,
        bytes memory
    ) external view {
        _beforeClaim(_tokenId, address(0), _quantity, address(0), 0, alp, bytes(""));
    }
}

contract DropERC1155Test_beforeClaim is BaseTest {
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

        vm.prank(deployer);
        proxy.setMaxTotalSupply(0, 1);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc.
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_revert_ExceedMaxSupply() public {
        DropERC1155.AllowlistProof memory alp;
        vm.expectRevert("exceed max total supply");
        proxy.beforeClaim(0, address(0), 2, address(0), 0, alp, bytes(""));
    }

    function test_NoRevert() public view {
        DropERC1155.AllowlistProof memory alp;
        proxy.beforeClaim(0, address(0), 1, address(0), 0, alp, bytes(""));
    }
}
