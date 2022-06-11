// // SPDX-License-Identifier: Apache-2.0
// pragma solidity ^0.8.0;

// import { Pack } from "contracts/pack/Pack.sol";
// import { IPack } from "contracts/interfaces/IPack.sol";

// // Test imports
// import { MockERC20 } from "./mocks/MockERC20.sol";
// import { Wallet } from "./utils/Wallet.sol";
// import "./utils/BaseTest.sol";

// contract PackTest is BaseTest {
//     Pack internal pack;

//     Wallet internal tokenOwner;
//     string internal packUri;
//     IPack.PackContent[] internal packContents;

//     function setUp() public override {
//         super.setUp();

//         pack = Pack(getContract("Pack"));

//         tokenOwner = getWallet();
//         packUri = "ipfs://";

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc721),
//                 tokenType: IPack.TokenType.ERC721,
//                 tokenId: 0,
//                 totalAmountPacked: 1,
//                 amountPerUnit: 1
//             })
//         );

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc1155),
//                 tokenType: IPack.TokenType.ERC1155,
//                 tokenId: 0,
//                 totalAmountPacked: 100,
//                 amountPerUnit: 5
//             })
//         );

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc20),
//                 tokenType: IPack.TokenType.ERC20,
//                 tokenId: 0,
//                 totalAmountPacked: 1000 ether,
//                 amountPerUnit: 20 ether
//             })
//         );

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc721),
//                 tokenType: IPack.TokenType.ERC721,
//                 tokenId: 1,
//                 totalAmountPacked: 1,
//                 amountPerUnit: 1
//             })
//         );

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc20),
//                 tokenType: IPack.TokenType.ERC20,
//                 tokenId: 0,
//                 totalAmountPacked: 1000 ether,
//                 amountPerUnit: 10 ether
//             })
//         );

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc721),
//                 tokenType: IPack.TokenType.ERC721,
//                 tokenId: 2,
//                 totalAmountPacked: 1,
//                 amountPerUnit: 1
//             })
//         );

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc721),
//                 tokenType: IPack.TokenType.ERC721,
//                 tokenId: 3,
//                 totalAmountPacked: 1,
//                 amountPerUnit: 1
//             })
//         );

//         packContents.push(
//             IPack.PackContent({
//                 assetContract: address(erc721),
//                 tokenType: IPack.TokenType.ERC721,
//                 tokenId: 4,
//                 totalAmountPacked: 1,
//                 amountPerUnit: 1
//             })
//         );

//         erc20.mint(address(tokenOwner), 2000 ether);
//         erc721.mint(address(tokenOwner), 5);
//         erc1155.mint(address(tokenOwner), 0, 100);

//         tokenOwner.setAllowanceERC20(address(erc20), address(pack), type(uint256).max);
//         tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), true);
//         tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), true);

//         vm.prank(deployer);
//         pack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Unit tests: `createPack`
//     //////////////////////////////////////////////////////////////*/

//     /**
//      *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
//      */
//     function test_state_createPack() public {
//         uint256 packId = pack.nextTokenId();
//         address recipient = address(1);

//         vm.prank(address(tokenOwner));
//         pack.createPack(packContents, packUri, 0, 1, recipient);

//         assertEq(packId + 1, pack.nextTokenId());

//         IPack.PackContent[] memory packed = pack.getPackContents(packId);
//         assertEq(packed.length, packContents.length);
//         for (uint256 i = 0; i < packed.length; i += 1) {
//             assertEq(packed[i].assetContract, packContents[i].assetContract);
//             assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
//             assertEq(packed[i].tokenId, packContents[i].tokenId);
//             assertEq(packed[i].totalAmountPacked, packContents[i].totalAmountPacked);
//         }

//         assertEq(packUri, pack.uri(packId));
//     }

//     /**
//      *  note: Testing token balances; token owner calls `createPack` to pack owned tokens.
//      */
//     function test_balances_createPack() public {
//         // ERC20 balance
//         assertEq(erc20.balanceOf(address(tokenOwner)), 2000 ether);
//         assertEq(erc20.balanceOf(address(pack)), 0);

//         // ERC721 balance
//         assertEq(erc721.ownerOf(0), address(tokenOwner));
//         assertEq(erc721.ownerOf(1), address(tokenOwner));
//         assertEq(erc721.ownerOf(2), address(tokenOwner));
//         assertEq(erc721.ownerOf(3), address(tokenOwner));
//         assertEq(erc721.ownerOf(4), address(tokenOwner));

//         // ERC1155 balance
//         assertEq(erc1155.balanceOf(address(tokenOwner), 0), 100);
//         assertEq(erc1155.balanceOf(address(pack), 0), 0);

//         uint256 packId = pack.nextTokenId();
//         address recipient = address(1);

//         vm.prank(address(tokenOwner));
//         pack.createPack(packContents, packUri, 0, 1, recipient);

//         // ERC20 balance
//         assertEq(erc20.balanceOf(address(tokenOwner)), 0);
//         assertEq(erc20.balanceOf(address(pack)), 2000 ether);

//         // ERC721 balance
//         assertEq(erc721.ownerOf(0), address(pack));
//         assertEq(erc721.ownerOf(1), address(pack));
//         assertEq(erc721.ownerOf(2), address(pack));
//         assertEq(erc721.ownerOf(3), address(pack));
//         assertEq(erc721.ownerOf(4), address(pack));

//         // ERC1155 balance
//         assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
//         assertEq(erc1155.balanceOf(address(pack), 0), 100);

//         // Pack token balance
//         assertEq(pack.balanceOf(address(recipient), packId), 175);
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Unit tests: `openPack`
//     //////////////////////////////////////////////////////////////*/

//     /**
//      *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
//      */
//     function test_state_openPack() public {
//         vm.warp(1000);
//         uint256 packId = pack.nextTokenId();
//         address recipient = address(1);

//         vm.prank(address(tokenOwner));
//         pack.createPack(packContents, packUri, 0, 1, recipient);

//         vm.prank(recipient, recipient);
//         pack.openPack(packId, 1);

//         assertEq(packUri, pack.uri(packId));
//         assertEq(pack.totalSupply(packId), 174);

//         IPack.PackContent[] memory packed = pack.getPackContents(packId);
//         assertEq(packed.length, 8);
//     }

//     function test_balances_openPack() public {
//         uint256 packId = pack.nextTokenId();
//         address recipient = address(1);

//         vm.prank(address(tokenOwner));
//         pack.createPack(packContents, packUri, 0, 1, recipient);

//         // ERC20 balance
//         assertEq(erc20.balanceOf(address(recipient)), 0);
//         assertEq(erc20.balanceOf(address(pack)), 2000 ether);

//         // ERC721 balance
//         assertEq(erc721.ownerOf(0), address(pack));
//         assertEq(erc721.ownerOf(1), address(pack));
//         assertEq(erc721.ownerOf(2), address(pack));
//         assertEq(erc721.ownerOf(3), address(pack));
//         assertEq(erc721.ownerOf(4), address(pack));

//         // ERC1155 balance
//         assertEq(erc1155.balanceOf(address(recipient), 0), 0);
//         assertEq(erc1155.balanceOf(address(pack), 0), 100);

//         vm.prank(recipient, recipient);
//         pack.openPack(packId, 1);

//         if (erc20.balanceOf(address(recipient)) > 0) {
//             assertTrue(
//                 erc20.balanceOf(address(recipient)) == 10 ether || erc20.balanceOf(address(recipient)) == 20 ether
//             );
//             assertEq(pack.balanceOf(address(recipient), packId), 174);
//         } else if (erc1155.balanceOf(address(recipient), 0) > 0) {
//             assertEq(erc1155.balanceOf(address(recipient), 0), 5);
//             assertEq(pack.balanceOf(address(recipient), packId), 174);
//         } else if (erc721.balanceOf(address(recipient)) > 0) {
//             assertEq(erc721.balanceOf(address(recipient)), 1);
//             assertEq(pack.balanceOf(address(recipient), packId), 174);
//         } else {
//             assertEq(pack.balanceOf(address(recipient), packId), 178);
//         }
//     }
// }
