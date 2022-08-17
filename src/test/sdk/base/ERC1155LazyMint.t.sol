// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ERC1155LazyMint } from "contracts/base/ERC1155LazyMint.sol";

import "contracts/lib/TWStrings.sol";

contract ERC1155LazyMintTest is DSTest, Test {
    using TWStrings for uint256;

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
        base = new ERC1155LazyMint("name", "symbol", admin, 0);

        // Lazy mint tokens
        vm.prank(admin);
        base.lazyMint(lazymintAmount, baseURI, "");

        assertEq(base.nextTokenIdToMint(), lazymintAmount);
    }

    function test_state_mintTo() public {
        uint256 tokenId = 0;
        uint256 amount = 100;

        vm.prank(admin);
        base.mintTo(nftHolder, tokenId, "", amount);

        assertEq(base.balanceOf(nftHolder, tokenId), amount);
        assertEq(base.totalSupply(tokenId), amount);
        assertEq(base.uri(tokenId), string(abi.encodePacked(baseURI, tokenId.toString())));
    }

    function test_revert_mintTo_unauthorizedCaller() public {
        uint256 tokenId = 0;
        uint256 amount = 100;

        vm.prank(nftHolder);
        vm.expectRevert("Not authorized to mint.");
        base.mintTo(nftHolder, tokenId, "", amount);
    }

    function test_revert_mintTo_invalidId() public {
        uint256 tokenId = base.nextTokenIdToMint();
        uint256 amount = 100;

        vm.prank(admin);
        vm.expectRevert("invalid id");
        base.mintTo(nftHolder, tokenId, "", amount);
    }

    function test_state_batchMintTo() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = nextId - (1 + i);
            amounts[i] = 100;
        }

        vm.prank(admin);
        base.batchMintTo(nftHolder, tokenIds, amounts, "");

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = tokenIds[i];

            assertEq(base.balanceOf(nftHolder, id), amounts[i]);
            assertEq(base.totalSupply(id), amounts[i]);
            assertEq(base.uri(id), string(abi.encodePacked(baseURI, id.toString())));
        }
    }

    function test_revert_batchMintTo_unauthorizedCaller() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = nextId - (1 + i);
            amounts[i] = 100;
        }

        vm.prank(nftHolder);
        vm.expectRevert("Not authorized to mint.");
        base.batchMintTo(nftHolder, tokenIds, amounts, "");
    }

    function test_revert_batchMintTo_mintingZeroTokens() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](0);

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = nextId - (1 + i);
        }

        vm.prank(admin);
        vm.expectRevert("Minting zero tokens.");
        base.batchMintTo(nftHolder, tokenIds, amounts, "");
    }

    function test_revert_batchMintTo_lengthMismatch() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint + 1);
        uint256[] memory amounts = new uint256[](numToMint);

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = nextId - (1 + i);
            amounts[i] = 100;
        }

        vm.prank(admin);
        vm.expectRevert("Length mismatch");
        base.batchMintTo(nftHolder, tokenIds, amounts, "");
    }

    function test_revert_batchMintTo_invalidId() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = nextId;
            amounts[i] = 100;
        }

        vm.prank(admin);
        vm.expectRevert("invalid id");
        base.batchMintTo(nftHolder, tokenIds, amounts, "");
    }
}
