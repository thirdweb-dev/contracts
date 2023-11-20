// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {}

contract TokenERC1155Test_Owner is BaseTest {
    address public implementation;
    address public proxy;

    MyTokenERC1155 internal tokenContract;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC1155());

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC1155.initialize,
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
        );

        tokenContract = MyTokenERC1155(proxy);
    }

    function test_owner() public {
        assertEq(tokenContract.owner(), deployer);
    }

    function test_owner_notDefaultAdmin() public {
        vm.prank(deployer);
        tokenContract.renounceRole(bytes32(0x00), deployer);

        assertEq(tokenContract.owner(), address(0));
    }
}
