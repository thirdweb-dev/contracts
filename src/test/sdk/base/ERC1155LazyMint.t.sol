// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ERC1155LazyMint } from "contracts/base/ERC1155LazyMint.sol";
import { Strings } from "contracts/lib/Strings.sol";

contract ERC1155LazyMintTest is DSTest, Test {
    using Strings for uint256;

    // Target contract
    ERC1155LazyMint internal base;

    // Signers
    address internal admin;
    address internal nftHolder;

    // Lazy mitning args
    uint256 internal lazymintAmount = 10;
    string internal baseURI = "ipfs://";

    function setUp() public {
        admin = address(0x123);
        nftHolder = address(0x456);

        vm.prank(admin);
        base = new ERC1155LazyMint(admin, "name", "symbol", admin, 0);

        // Lazy mint tokens
        vm.prank(admin);
        base.lazyMint(lazymintAmount, baseURI, "");

        assertEq(base.nextTokenIdToMint(), lazymintAmount);
    }

    function test_state_claim() public {
        uint256 tokenId = 0;
        uint256 amount = 100;

        vm.prank(nftHolder);
        base.claim(nftHolder, tokenId, amount);

        assertEq(base.balanceOf(nftHolder, tokenId), amount);
        assertEq(base.totalSupply(tokenId), amount);
        assertEq(base.uri(tokenId), string(abi.encodePacked(baseURI, tokenId.toString())));
    }

    function test_revert_mintTo_invalidId() public {
        uint256 tokenId = base.nextTokenIdToMint();
        uint256 amount = 100;

        vm.prank(nftHolder);
        vm.expectRevert("invalid id");
        base.claim(nftHolder, tokenId, amount);
    }
}
