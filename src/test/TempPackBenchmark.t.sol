// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TempPack } from "contracts/pack/TempPack.sol";
import { ITempPack } from "contracts/interfaces/ITempPack.sol";
import { ITokenBundle } from "contracts/feature/interface/ITokenBundle.sol";

// Test imports
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Wallet } from "./utils/Wallet.sol";
import "./utils/BaseTest.sol";

contract TempCreatePackBenchmarkTest is BaseTest {
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

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 1,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc20),
        //         tokenType: ITokenBundle.TokenType.ERC20,
        //         tokenId: 0,
        //         totalAmount: 1000 ether
        //     })
        // );
        // amountsPerUnit.push(10 ether);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 2,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 3,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 4,
        //         totalAmount: 1
        //     })
        // );
        amountsPerUnit.push(1);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 5);
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setAllowanceERC20(address(erc20), address(tempPack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(tempPack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(tempPack), true);

        vm.prank(deployer);
        tempPack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        vm.startPrank(address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
     */
    function test_benchmark_createPack() public {
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, address(0x123));
    }
}


contract TempOpenPackBenchmarkTest is BaseTest {
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

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 1,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc20),
        //         tokenType: ITokenBundle.TokenType.ERC20,
        //         tokenId: 0,
        //         totalAmount: 1000 ether
        //     })
        // );
        // amountsPerUnit.push(10 ether);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 2,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 3,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 4,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 5);
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setAllowanceERC20(address(erc20), address(tempPack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(tempPack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(tempPack), true);

        vm.prank(deployer);
        tempPack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, address(0x123));

        vm.startPrank(address(0x123), address(0x123));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `openPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
     */
    function test_benchmark_openPack() public {
        tempPack.openPack(0, 1);
    }
}