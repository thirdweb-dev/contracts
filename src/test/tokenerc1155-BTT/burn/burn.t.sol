// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {}

contract TokenERC1155Test_Burn is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    string public uri;
    uint256 public amount;

    MyTokenERC1155 internal tokenContract;

    event MetadataUpdate(uint256 _tokenId);
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);

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
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        // burn
        vm.expectRevert("ERC1155: caller is not owner nor approved.");
        tokenContract.burn(recipient, _tokenIdToMint, amount);
    }

    function test_burn_whenOwner_invalidAmount() public {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        // burn
        vm.prank(recipient);
        vm.expectRevert();
        tokenContract.burn(recipient, _tokenIdToMint, amount + 1);
    }

    function test_burn_whenOwner() public {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        // burn
        vm.prank(recipient);
        tokenContract.burn(recipient, _tokenIdToMint, amount);

        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), 0);
    }

    function test_burn_whenApproved() public {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        vm.prank(recipient);
        tokenContract.setApprovalForAll(caller, true);

        // burn
        vm.prank(caller);
        tokenContract.burn(recipient, _tokenIdToMint, amount);

        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), 0);
    }
}
