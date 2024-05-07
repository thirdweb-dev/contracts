// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ERC1155Base } from "contracts/base/ERC1155Base.sol";
import { Strings } from "contracts/lib/Strings.sol";

contract ERC1155BaseTest is DSTest, Test {
    using Strings for uint256;

    // Target contract
    ERC1155Base internal base;

    // Signers
    address internal admin;
    address internal nftHolder;

    function setUp() public {
        admin = address(0x123);
        nftHolder = address(0x456);

        vm.prank(admin);
        base = new ERC1155Base(admin, "name", "symbol", admin, 0);
    }

    // ================== `mintTo` tests ========================

    function test_state_mintTo_newNFTs() public {
        uint256 tokenId = type(uint256).max;
        string memory tokenURI = "ipfs://";
        uint256 amount = 100;

        uint256 expectedTokenIdMinted = base.nextTokenIdToMint();

        vm.prank(admin);
        base.mintTo(nftHolder, tokenId, tokenURI, amount);

        assertEq(base.balanceOf(nftHolder, expectedTokenIdMinted), amount);
        assertEq(base.totalSupply(expectedTokenIdMinted), amount);
        assertEq(base.nextTokenIdToMint(), expectedTokenIdMinted + 1);
        assertEq(base.uri(expectedTokenIdMinted), tokenURI);
    }

    function test_state_mintTo_existingNFTs() public {
        string memory tokenURI = "ipfs://";
        uint256 startAmount = 1;

        uint256 tokenIdMinted = base.nextTokenIdToMint();

        vm.prank(admin);
        base.mintTo(admin, type(uint256).max, tokenURI, startAmount);

        assertEq(base.uri(tokenIdMinted), tokenURI);
        assertEq(base.totalSupply(tokenIdMinted), startAmount);
        assertEq(base.nextTokenIdToMint(), tokenIdMinted + 1);

        uint256 additionalAmount = 100;

        vm.prank(admin);
        base.mintTo(nftHolder, tokenIdMinted, "", additionalAmount);

        assertEq(base.balanceOf(nftHolder, tokenIdMinted), additionalAmount);
        assertEq(base.totalSupply(tokenIdMinted), additionalAmount + startAmount);
    }

    function test_revert_mintTo_unauthorizedCaller() public {
        uint256 tokenId = type(uint256).max;
        string memory tokenURI = "ipfs://";
        uint256 amount = 100;

        vm.prank(nftHolder);
        vm.expectRevert("Not authorized to mint.");
        base.mintTo(nftHolder, tokenId, tokenURI, amount);
    }

    function test_revert_mintTo_invalidId() public {
        string memory tokenURI = "ipfs://";
        uint256 amount = 100;

        uint256 nextId = base.nextTokenIdToMint();

        vm.prank(admin);
        vm.expectRevert("invalid id");
        base.mintTo(nftHolder, nextId, tokenURI, amount);
    }

    // ================== `mintTo` tests ========================

    function test_state_batchMintTo_newNFTs() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            amounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(nftHolder, id), amounts[i]);
            assertEq(base.totalSupply(id), amounts[i]);
            assertEq(base.uri(id), string(abi.encodePacked(baseURI, id.toString())));
        }
    }

    function test_state_batchMintTo_existingNFTs() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory startAmounts = new uint256[](numToMint);
        uint256[] memory nextAmounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            startAmounts[i] = 1;
            nextAmounts[i] = 99;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        base.batchMintTo(admin, tokenIds, startAmounts, baseURI);

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(admin, id), startAmounts[i]);
            assertEq(base.totalSupply(id), startAmounts[i]);
            assertEq(base.uri(id), string(abi.encodePacked(baseURI, id.toString())));
        }

        vm.prank(admin);
        base.batchMintTo(nftHolder, expectedTokenIds, nextAmounts, "");

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(nftHolder, id), nextAmounts[i]);
            assertEq(base.totalSupply(id), startAmounts[i] + nextAmounts[i]);
            assertEq(base.uri(id), string(abi.encodePacked(baseURI, id.toString())));
        }
    }

    function test_state_batchMintTo_newAndExistingNFTs() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory startAmounts = new uint256[](numToMint);
        uint256[] memory nextAmounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            startAmounts[i] = 1;
            nextAmounts[i] = 99;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        base.batchMintTo(admin, tokenIds, startAmounts, baseURI);

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(admin, id), startAmounts[i]);
            assertEq(base.totalSupply(id), startAmounts[i]);
            assertEq(base.uri(id), string(abi.encodePacked(baseURI, id.toString())));
        }

        uint256[] memory newAndExistingTokenIds = new uint256[](numToMint + 1);
        uint256[] memory newAmounts = new uint256[](numToMint + 1);
        for (uint256 i = 0; i < numToMint; i += 1) {
            newAndExistingTokenIds[i] = expectedTokenIds[i];
            newAmounts[i] = nextAmounts[i];
        }
        newAndExistingTokenIds[numToMint] = type(uint256).max;
        newAmounts[numToMint] = 100;

        uint256 expectedNewId = base.nextTokenIdToMint();
        string memory baseURIForNewNFT = "newipfs://";

        vm.prank(admin);
        base.batchMintTo(nftHolder, newAndExistingTokenIds, newAmounts, baseURIForNewNFT);

        for (uint256 i = 0; i < newAndExistingTokenIds.length; i += 1) {
            if (i < numToMint) {
                uint256 id = newAndExistingTokenIds[i];

                assertEq(base.balanceOf(nftHolder, id), newAmounts[i]);
                assertEq(base.totalSupply(id), startAmounts[i] + newAmounts[i]);
                assertEq(base.uri(id), string(abi.encodePacked(baseURI, id.toString())));
            } else {
                uint256 id = expectedNewId;
                assertEq(base.balanceOf(nftHolder, id), newAmounts[i]);
                assertEq(base.totalSupply(id), newAmounts[i]);
                assertEq(base.uri(id), string(abi.encodePacked(baseURIForNewNFT, id.toString())));
            }
        }
    }

    function test_revert_batchMintTo_unauthorizedCaller() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            amounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(nftHolder);
        vm.expectRevert("Not authorized to mint.");
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);
    }

    function test_revert_batchMintTo_mintingZeroTokens() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](0);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        vm.expectRevert("Minting zero tokens.");
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);
    }

    function test_revert_batchMintTo_lengthMismatch() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint + 1);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            amounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        vm.expectRevert("Length mismatch.");
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);
    }

    function test_revert_batchMintTo_invalidId() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = i;
            amounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        vm.expectRevert("invalid id");
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);
    }

    function test_state_burn() public {
        uint256 tokenId = type(uint256).max;
        string memory tokenURI = "ipfs://";
        uint256 amount = 100;

        uint256 expectedTokenIdMinted = base.nextTokenIdToMint();

        vm.prank(admin);
        base.mintTo(nftHolder, tokenId, tokenURI, amount);

        assertEq(base.balanceOf(nftHolder, expectedTokenIdMinted), amount);
        assertEq(base.totalSupply(expectedTokenIdMinted), amount);

        vm.prank(nftHolder);
        base.burn(nftHolder, expectedTokenIdMinted, amount);

        assertEq(base.balanceOf(nftHolder, expectedTokenIdMinted), 0);
        assertEq(base.totalSupply(expectedTokenIdMinted), 0);
    }

    function test_revert_burn_unapprovedCaller() public {
        uint256 tokenId = type(uint256).max;
        string memory tokenURI = "ipfs://";
        uint256 amount = 100;

        uint256 expectedTokenIdMinted = base.nextTokenIdToMint();

        vm.prank(admin);
        base.mintTo(nftHolder, tokenId, tokenURI, amount);

        assertEq(base.balanceOf(nftHolder, expectedTokenIdMinted), amount);
        assertEq(base.totalSupply(expectedTokenIdMinted), amount);

        vm.prank(admin);
        vm.expectRevert("Unapproved caller");
        base.burn(nftHolder, expectedTokenIdMinted, amount);
    }

    function test_revert_burn_notEnoughTokensOwned() public {
        uint256 tokenId = type(uint256).max;
        string memory tokenURI = "ipfs://";
        uint256 amount = 100;

        uint256 expectedTokenIdMinted = base.nextTokenIdToMint();

        vm.prank(admin);
        base.mintTo(nftHolder, tokenId, tokenURI, amount);

        assertEq(base.balanceOf(nftHolder, expectedTokenIdMinted), amount);
        assertEq(base.totalSupply(expectedTokenIdMinted), amount);

        vm.prank(nftHolder);
        vm.expectRevert("Not enough tokens owned");
        base.burn(nftHolder, expectedTokenIdMinted, amount + 1);
    }

    function test_state_burnBatch() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            amounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(nftHolder, id), amounts[i]);
            assertEq(base.totalSupply(id), amounts[i]);
        }

        vm.prank(nftHolder);
        base.burnBatch(nftHolder, expectedTokenIds, amounts);

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(nftHolder, id), 0);
            assertEq(base.totalSupply(id), 0);
        }
    }

    function test_revert_burnBatch_unapprovedCaller() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            amounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(nftHolder, id), amounts[i]);
            assertEq(base.totalSupply(id), amounts[i]);
        }

        vm.prank(admin);
        vm.expectRevert("Unapproved caller");
        base.burnBatch(nftHolder, expectedTokenIds, amounts);
    }

    function test_revert_burnBatch_lengthMismatch() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory mockAmounts = new uint256[](numToMint + 1);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            amounts[i] = 100;
            mockAmounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);

        for (uint256 i = 0; i < numToMint; i += 1) {
            uint256 id = expectedTokenIds[i];

            assertEq(base.balanceOf(nftHolder, id), amounts[i]);
            assertEq(base.totalSupply(id), amounts[i]);
        }

        vm.prank(nftHolder);
        vm.expectRevert("Length mismatch");
        base.burnBatch(nftHolder, expectedTokenIds, mockAmounts);
    }

    function test_revert_burnBatch_notEnoughTokensOwned() public {
        uint256 numToMint = 3;
        uint256[] memory tokenIds = new uint256[](numToMint);
        uint256[] memory amounts = new uint256[](numToMint);
        uint256[] memory expectedTokenIds = new uint256[](numToMint);
        string memory baseURI = "ipfs://";

        uint256 nextId = base.nextTokenIdToMint();

        for (uint256 i = 0; i < numToMint; i += 1) {
            tokenIds[i] = type(uint256).max;
            amounts[i] = 100;

            expectedTokenIds[i] = nextId;
            nextId += 1;
        }

        vm.prank(admin);
        base.batchMintTo(nftHolder, tokenIds, amounts, baseURI);

        for (uint256 i = 0; i < numToMint; i += 1) {
            amounts[i] += 1;
        }

        vm.prank(nftHolder);
        vm.expectRevert("Not enough tokens owned");
        base.burnBatch(nftHolder, expectedTokenIds, amounts);
    }
}
