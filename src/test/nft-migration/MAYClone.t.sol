// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { BuggyMAYClone } from "./BuggyMAYClone.sol";
import { MAYCloneMigration } from "./MAYCloneMigration.sol";

import "../utils/BaseTest.sol";

contract MAYCloneTest is BaseTest {
    BuggyMAYClone internal buggymayc;
    MAYCloneMigration internal migrator;

    uint256 originalAmount = 100;
    address userOne;
    address userTwo;

    function setUp() public override {
        super.setUp();
        userOne = address(0x345);
        userTwo = address(0x567);

        vm.startPrank(deployer);
        buggymayc = new BuggyMAYClone("Buggy MAYC", "BMAYC", deployer, 0, address(erc721), address(erc1155));
        buggymayc.lazyMint(originalAmount, "mayc://", "");
        vm.stopPrank();

        erc721.mint(userOne, 10);
        erc1155.mint(userOne, 0, 10);

        erc721.mint(userTwo, 10);
        erc1155.mint(userTwo, 0, 10);

        vm.startPrank(userOne);
        erc721.setApprovalForAll(address(buggymayc), true);
        erc1155.setApprovalForAll(address(buggymayc), true);
        vm.stopPrank();

        vm.startPrank(userTwo);
        erc721.setApprovalForAll(address(buggymayc), true);
        erc1155.setApprovalForAll(address(buggymayc), true);
        vm.stopPrank();

        // MAYCloneMigration
        vm.startPrank(deployer);
        migrator = new MAYCloneMigration(
            "Migration MAYC",
            "MMAYC",
            deployer,
            0,
            address(erc721),
            address(erc1155),
            deployer,
            address(buggymayc),
            originalAmount
        );
        vm.stopPrank();
    }

    function test_claim_mayc() public {
        vm.prank(userOne);
        buggymayc.claim(userOne, 10);

        assertEq(buggymayc.balanceOf(userOne), 10);

        vm.prank(userOne);
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        buggymayc.transferFrom(userOne, userTwo, 0);

        vm.prank(userOne);
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        buggymayc.burn(0);
    }

    function test_migrate_to_new_contract() public {
        // userOne and userTwo claim alternate tokens from BuggyMAYC
        for (uint256 i = 0; i < 20; i += 1) {
            if (i % 2 == 0) {
                vm.prank(userOne);
                buggymayc.claim(userOne, 1);
                assertEq(buggymayc.ownerOf(i), userOne);
            } else {
                vm.prank(userTwo);
                buggymayc.claim(userTwo, 1);
                assertEq(buggymayc.ownerOf(i), userTwo);
            }
        }

        // ======== migrate tokens to new contract ===========
        // approve tokens to migrator
        vm.prank(userOne);
        buggymayc.setApprovalForAll(address(migrator), true);

        vm.prank(userTwo);
        buggymayc.setApprovalForAll(address(migrator), true);

        // mint more serum and approve to migrator
        erc1155.mint(deployer, 0, 20);
        vm.prank(deployer);
        erc1155.setApprovalForAll(address(migrator), true);

        for (uint256 i = 0; i < 20; i += 1) {
            // check ownership etc. before migration
            vm.expectRevert("Invalid tokenId");
            migrator.ownerOf(i);
            vm.expectRevert("Invalid tokenId");
            migrator.tokenURI(i);

            string memory _tokenURI = buggymayc.tokenURI(i);

            if (i % 2 == 0) {
                vm.prank(userOne);
                migrator.migrateToken(i);
                assertEq(migrator.ownerOf(i), userOne);
                assertEq(migrator.tokenURI(i), _tokenURI);
            } else {
                vm.prank(userTwo);
                migrator.migrateToken(i);
                assertEq(migrator.ownerOf(i), userTwo);
                assertEq(migrator.tokenURI(i), _tokenURI);
            }
        }

        // ======== check transfers of migrated tokens ===========

        for (uint256 i = 0; i < 20; i += 1) {
            if (i % 2 == 0) {
                vm.prank(userOne);
                migrator.transferFrom(userOne, userTwo, i);
                assertEq(migrator.ownerOf(i), userTwo);
            } else {
                vm.prank(userTwo);
                migrator.transferFrom(userTwo, userOne, i);
                assertEq(migrator.ownerOf(i), userOne);
            }
        }
    }

    function test_revert_migratingUnOwnedTokens() public {
        // userOne and userTwo claim alternate tokens from BuggyMAYC
        for (uint256 i = 0; i < 20; i += 1) {
            if (i % 2 == 0) {
                vm.prank(userOne);
                buggymayc.claim(userOne, 1);
                assertEq(buggymayc.ownerOf(i), userOne);
            } else {
                vm.prank(userTwo);
                buggymayc.claim(userTwo, 1);
                assertEq(buggymayc.ownerOf(i), userTwo);
            }
        }

        vm.prank(address(0x999));
        vm.expectRevert("Not owner");
        migrator.migrateToken(10);

        vm.prank(address(0x999));
        vm.expectRevert("Migrating invalid tokenId");
        migrator.migrateToken(100);
    }

    function test_revert_migratingMigratedTokens() public {
        // userOne and userTwo claim alternate tokens from BuggyMAYC
        for (uint256 i = 0; i < 20; i += 1) {
            if (i % 2 == 0) {
                vm.prank(userOne);
                buggymayc.claim(userOne, 1);
                assertEq(buggymayc.ownerOf(i), userOne);
            } else {
                vm.prank(userTwo);
                buggymayc.claim(userTwo, 1);
                assertEq(buggymayc.ownerOf(i), userTwo);
            }
        }

        // ======== migrate tokens to new contract ===========
        // approve tokens to migrator
        vm.prank(userOne);
        buggymayc.setApprovalForAll(address(migrator), true);

        vm.prank(userTwo);
        buggymayc.setApprovalForAll(address(migrator), true);

        // mint more serum and approve to migrator
        erc1155.mint(deployer, 0, 20);
        vm.prank(deployer);
        erc1155.setApprovalForAll(address(migrator), true);

        for (uint256 i = 0; i < 20; i += 1) {
            if (i % 2 == 0) {
                vm.prank(userOne);
                migrator.migrateToken(i);
            } else {
                vm.prank(userTwo);
                migrator.migrateToken(i);
            }
        }

        // try re-migrating
        for (uint256 i = 0; i < 20; i += 1) {
            vm.prank(userOne);
            vm.expectRevert("Already migrated");
            migrator.migrateToken(i);
        }
    }

    function test_lazyMint_new_batch() public {
        vm.prank(deployer);
        migrator.lazyMint(100, "mayc://", "");

        assertEq(migrator.nextTokenIdToClaim(), 100);
        assertEq(migrator.nextTokenIdToMint(), 200);

        address randomUser = address(0x999);

        erc721.mint(randomUser, 10);
        erc1155.mint(randomUser, 0, 10);

        vm.startPrank(randomUser);
        erc721.setApprovalForAll(address(migrator), true);
        erc1155.setApprovalForAll(address(migrator), true);
        vm.stopPrank();

        vm.prank(randomUser);
        migrator.claim(randomUser, 10);

        assertEq(migrator.balanceOf(randomUser), 10);

        for (uint256 i = 100; i < 110; i += 1) {
            assertEq(migrator.ownerOf(i), randomUser);
        }

        // transfer tokens without issue
        vm.prank(randomUser);
        // vm.expectRevert("ERC1155: burn amount exceeds balance");
        migrator.transferFrom(randomUser, userOne, 100);
        assertEq(migrator.ownerOf(100), userOne);

        vm.prank(randomUser);
        // vm.expectRevert("ERC1155: burn amount exceeds balance");
        migrator.burn(101);
    }
}
