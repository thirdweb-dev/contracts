// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {}

contract TokenERC1155Test_BurnBatch is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    string public uri;
    uint256 public amount;

    MyTokenERC1155 internal tokenContract;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC1155());
        caller = getActor(1);
        recipient = getActor(2);

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
        uri = "uri";
        amount = 100;

        vm.prank(deployer);
        tokenContract.grantRole(keccak256("MINTER_ROLE"), caller);
    }

    function test_burn_whenNotOwnerNorApproved() public {
        // mint two tokenIds
        vm.startPrank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 10;
        amounts[1] = 10;

        // burn
        vm.expectRevert("ERC1155: caller is not owner nor approved.");
        tokenContract.burnBatch(recipient, ids, amounts);
    }

    function test_burn_whenOwner_invalidAmount() public {
        // mint two tokenIds
        vm.startPrank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 1000 ether;
        amounts[1] = 10;

        // burn
        vm.prank(recipient);
        vm.expectRevert();
        tokenContract.burnBatch(recipient, ids, amounts);
    }

    function test_burn_whenOwner() public {
        // mint two tokenIds
        vm.startPrank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 10;
        amounts[1] = 10;

        // burn
        vm.prank(recipient);
        tokenContract.burnBatch(recipient, ids, amounts);

        assertEq(tokenContract.balanceOf(recipient, ids[0]), amount - amounts[0]);
        assertEq(tokenContract.balanceOf(recipient, ids[1]), amount - amounts[1]);
    }

    function test_burn_whenApproved() public {
        // mint two tokenIds
        vm.startPrank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        ids[0] = 0;
        ids[1] = 1;
        amounts[0] = 10;
        amounts[1] = 10;

        vm.prank(recipient);
        tokenContract.setApprovalForAll(caller, true);

        // burn
        vm.prank(caller);
        tokenContract.burnBatch(recipient, ids, amounts);

        assertEq(tokenContract.balanceOf(recipient, ids[0]), amount - amounts[0]);
        assertEq(tokenContract.balanceOf(recipient, ids[1]), amount - amounts[1]);
    }
}
