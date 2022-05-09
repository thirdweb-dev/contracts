// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";
import "../utils/Wallet.sol";
import "../mocks/MockERC20.sol";
import "../mocks/MockERC721.sol";
import "../mocks/MockERC1155.sol";

import "contracts/multiwrap/Multiwrap.sol";
import "contracts/interfaces/IMultiwrap.sol";

contract MultiwrapBenchmarkTest is BaseTest {
    // Target contract
    Multiwrap internal multiwrap;

    // Actors
    Wallet internal tokenOwner;
    Wallet internal wrappedTokenRecipient;

    // Benchmark parameters
    string internal uriForWrappedToken = "ipfs://wrappedNFT";
    IMultiwrap.Token[] internal wrappedContents;

    uint256 internal erc721TokenId = 0;
    uint256 internal erc1155TokenId = 0;
    uint256 internal erc1155Amount = 50;
    uint256 internal erc20Amount = 100 ether;

    IMultiwrap.Token[] internal fiveERC721NFts;
    IMultiwrap.Token[] internal oneERC721NFTWithERC20Token;
    IMultiwrap.Token[] internal allThreeKindsOfTokens;

    //  =====   Set up  =====
    function setUp() public override {
        super.setUp();

        // Get Multiwrap contract.
        multiwrap = Multiwrap(getContract("Multiwrap"));

        vm.label(address(erc20), "ERC20");
        vm.label(address(erc721), "ERC721");
        vm.label(address(erc1155), "ERC1155");
        vm.label(address(multiwrap), "Multiwrap");

        // Get test actors.
        tokenOwner = new Wallet();
        wrappedTokenRecipient = new Wallet();

        // Grant MINTER_ROLE to `tokenOwner`
        vm.prank(deployer);
        multiwrap.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        // Mint mock ERC20/721/1155 tokens to `tokenOwner`

        erc20.mint(address(tokenOwner), erc20Amount);
        erc721.mint(address(tokenOwner), 5);
        erc1155.mint(address(tokenOwner), erc1155TokenId, erc1155Amount);

        // Allow Multiwrap to transfer tokens.
        tokenOwner.setAllowanceERC20(address(erc20), address(multiwrap), erc20Amount);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(multiwrap), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(multiwrap), true);

        // Prepare wrapped contents.

        for (uint256 i = 0; i < 5; i += 1) {
            fiveERC721NFts.push(
                IMultiwrap.Token({
                    assetContract: address(erc721),
                    tokenType: IMultiwrap.TokenType.ERC721,
                    tokenId: i,
                    amount: 1
                })
            );
        }

        wrappedContents.push(
            IMultiwrap.Token({
                assetContract: address(erc20),
                tokenType: IMultiwrap.TokenType.ERC20,
                tokenId: 0,
                amount: erc20Amount
            })
        );
        wrappedContents.push(
            IMultiwrap.Token({
                assetContract: address(erc721),
                tokenType: IMultiwrap.TokenType.ERC721,
                tokenId: erc721TokenId,
                amount: 1
            })
        );
        wrappedContents.push(
            IMultiwrap.Token({
                assetContract: address(erc1155),
                tokenType: IMultiwrap.TokenType.ERC1155,
                tokenId: erc1155TokenId,
                amount: erc1155Amount
            })
        );

        oneERC721NFTWithERC20Token.push(
            IMultiwrap.Token({
                assetContract: address(erc20),
                tokenType: IMultiwrap.TokenType.ERC20,
                tokenId: 0,
                amount: erc20Amount
            })
        );
        oneERC721NFTWithERC20Token.push(
            IMultiwrap.Token({
                assetContract: address(erc721),
                tokenType: IMultiwrap.TokenType.ERC721,
                tokenId: erc721TokenId,
                amount: 1
            })
        );

        vm.startPrank(address(tokenOwner));
    }

    function testGas_wrap_fiveERC721NFTs() public {
        multiwrap.wrap(fiveERC721NFts, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function testGas_wrap_oneERC721NFTWithERC20Token() public {
        multiwrap.wrap(oneERC721NFTWithERC20Token, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function testGas_wrap_allThreeKindsOfTokens() public {
        multiwrap.wrap(allThreeKindsOfTokens, uriForWrappedToken, address(wrappedTokenRecipient));
    }
}
