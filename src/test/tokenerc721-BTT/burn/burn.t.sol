// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {}

contract TokenERC721Test_Burn is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    string public uri;

    MyTokenERC721 internal tokenContract;

    event MetadataUpdate(uint256 _tokenId);
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC721());
        caller = getActor(1);
        recipient = getActor(2);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC721.initialize,
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

        tokenContract = MyTokenERC721(proxy);
        uri = "uri";

        vm.prank(deployer);
        tokenContract.grantRole(keccak256("MINTER_ROLE"), caller);
    }

    function test_burn_whenNotOwnerNorApproved() public {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintTo(recipient, uri);

        // burn
        vm.expectRevert("ERC721Burnable: caller is not owner nor approved");
        tokenContract.burn(_tokenId);
    }

    function test_burn_whenOwner() public {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintTo(recipient, uri);

        // burn
        vm.prank(recipient);
        tokenContract.burn(_tokenId);

        vm.expectRevert(); // checking non-existent token, because burned
        tokenContract.ownerOf(_tokenId);
    }

    function test_burn_whenApproved() public {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintTo(recipient, uri);

        vm.prank(recipient);
        tokenContract.setApprovalForAll(caller, true);

        // burn
        vm.prank(caller);
        tokenContract.burn(_tokenId);

        vm.expectRevert(); // checking non-existent token, because burned
        tokenContract.ownerOf(_tokenId);
    }
}
