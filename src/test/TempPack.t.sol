// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TempPack } from "contracts/pack/TempPack.sol";
import { ITempPack } from "contracts/interfaces/ITempPack.sol";
import { ITokenBundle } from "contracts/feature/interface/ITokenBundle.sol";

// Test imports
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Wallet } from "./utils/Wallet.sol";
import "./utils/BaseTest.sol";

contract TempPackTest is BaseTest {
    TempPack internal tempPack;

    Wallet internal tokenOwner;
    string internal packUri;
    ITokenBundle.Token[] internal packContents;
    uint256[] internal amountsPerUnit;

    function setUp() public override {
        super.setUp();

        tempPack = TempPack(getContract("TempPack"));

        tokenOwner = getWallet();
        packUri = "ipfs://";

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        amountsPerUnit.push(10 ether);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );
        amountsPerUnit.push(5);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        amountsPerUnit.push(20 ether);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 1,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 2,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 3,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 4,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 5);
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setAllowanceERC20(address(erc20), address(tempPack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(tempPack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(tempPack), true);

        vm.prank(deployer);
        tempPack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
     */
    function test_state_createPack() public {
        uint256 packId = tempPack.nextTokenId();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        assertEq(packId + 1, tempPack.nextTokenId());

        (ITokenBundle.Token[] memory packed, ) = tempPack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        assertEq(packUri, tempPack.uri(packId));
    }

    /**
     *  note: Testing token balances; token owner calls `createPack` to pack owned tokens.
     */
    function test_balances_createPack() public {
        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 2000 ether);
        assertEq(erc20.balanceOf(address(tempPack)), 0);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(tokenOwner));
        assertEq(erc721.ownerOf(1), address(tokenOwner));
        assertEq(erc721.ownerOf(2), address(tokenOwner));
        assertEq(erc721.ownerOf(3), address(tokenOwner));
        assertEq(erc721.ownerOf(4), address(tokenOwner));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 100);
        assertEq(erc1155.balanceOf(address(tempPack), 0), 0);

        uint256 packId = tempPack.nextTokenId();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(tempPack)), 2000 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(tempPack));
        assertEq(erc721.ownerOf(1), address(tempPack));
        assertEq(erc721.ownerOf(2), address(tempPack));
        assertEq(erc721.ownerOf(3), address(tempPack));
        assertEq(erc721.ownerOf(4), address(tempPack));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(tempPack), 0), 100);

        // TempPack wrapped token balance
        assertEq(tempPack.balanceOf(address(recipient), packId), 175);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `openPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
     */
    function test_state_openPack() public {
        uint256 packId = tempPack.nextTokenId();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        vm.prank(recipient, recipient);
        tempPack.openPack(packId, 1);

        assertEq(packUri, tempPack.uri(packId));
        // assertEq(0, tempPack.getTokenCountOfBundle(packId));
        if(erc20.balanceOf(address(recipient)) > 0) {
            assertTrue(erc20.balanceOf(address(recipient)) == 10 ether || erc20.balanceOf(address(recipient)) == 20 ether);
            assertEq(tempPack.balanceOf(address(recipient), packId), 174);
        } else if(erc1155.balanceOf(address(recipient), 0) > 0) {
            assertEq(erc1155.balanceOf(address(recipient), 0), 5);
            assertEq(tempPack.balanceOf(address(recipient), packId), 174);
        } else if(erc721.balanceOf(address(recipient)) > 0) {
            assertEq(erc721.balanceOf(address(recipient)), 1);
            assertEq(tempPack.balanceOf(address(recipient), packId), 174);
        } else {
            assertEq(tempPack.balanceOf(address(recipient), packId), 178);
        }
    }
}