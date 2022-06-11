// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// import { Pack } from "contracts/pack/Pack.sol";
// import { IPack } from "contracts/interfaces/IPack.sol";

// // Test imports
// import { MockERC20 } from "./mocks/MockERC20.sol";
// import { Wallet } from "./utils/Wallet.sol";
// import "./utils/BaseTest.sol";

// contract CreatePackBenchmarkTest is BaseTest {
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

//         vm.startPrank(address(tokenOwner));
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Unit tests: `createPack`
//     //////////////////////////////////////////////////////////////*/

//     /**
//      *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
//      */
//     function test_benchmark_createPack() public {
//         pack.createPack(packContents, packUri, 0, 1, address(0x123));
//     }
// }

// contract OpenPackBenchmarkTest is BaseTest {
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

//         // packContents.push(
//         //     IPack.PackContent({
//         //         assetContract: address(erc721),
//         //         tokenType: IPack.TokenType.ERC721,
//         //         tokenId: 1,
//         //         totalAmountPacked: 1,
//         //         amountPerUnit: 1
//         //     })
//         // );

//         // packContents.push(
//         //     IPack.PackContent({
//         //         assetContract: address(erc20),
//         //         tokenType: IPack.TokenType.ERC20,
//         //         tokenId: 0,
//         //         totalAmountPacked: 1000 ether,
//         //         amountPerUnit: 10 ether
//         //     })
//         // );

//         // packContents.push(
//         //     IPack.PackContent({
//         //         assetContract: address(erc721),
//         //         tokenType: IPack.TokenType.ERC721,
//         //         tokenId: 2,
//         //         totalAmountPacked: 1,
//         //         amountPerUnit: 1
//         //     })
//         // );

//         // packContents.push(
//         //     IPack.PackContent({
//         //         assetContract: address(erc721),
//         //         tokenType: IPack.TokenType.ERC721,
//         //         tokenId: 3,
//         //         totalAmountPacked: 1,
//         //         amountPerUnit: 1
//         //     })
//         // );

//         // packContents.push(
//         //     IPack.PackContent({
//         //         assetContract: address(erc721),
//         //         tokenType: IPack.TokenType.ERC721,
//         //         tokenId: 4,
//         //         totalAmountPacked: 1,
//         //         amountPerUnit: 1
//         //     })
//         // );

//         erc20.mint(address(tokenOwner), 2000 ether);
//         erc721.mint(address(tokenOwner), 5);
//         erc1155.mint(address(tokenOwner), 0, 100);

//         tokenOwner.setAllowanceERC20(address(erc20), address(pack), type(uint256).max);
//         tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), true);
//         tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), true);

//         vm.prank(deployer);
//         pack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

//         vm.prank(address(tokenOwner));
//         pack.createPack(packContents, packUri, 0, 1, address(0x123));

//         vm.startPrank(address(0x123), address(0x123));
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Unit tests: `openPack`
//     //////////////////////////////////////////////////////////////*/

//     /**
//      *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
//      */
//     function test_benchmark_openPack() public {
//         pack.openPack(0, 1);
//     }
// }
