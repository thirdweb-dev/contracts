// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./utils/BaseTest.sol";
import "./utils/Wallet.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC1155.sol";

import "contracts/multiwrap/Multiwrap.sol";
import "contracts/interfaces/IMultiwrap.sol";

interface IMultiwrapData {
    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(
        address indexed wrapper,
        address indexed recipientOfWrappedToken,
        uint256 indexed tokenIdOfWrappedToken,
        IMultiwrap.Token[] wrappedContents
    );

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed unwrapper,
        address indexed recipientOfWrappedContents,
        uint256 indexed tokenIdOfWrappedToken,
        IMultiwrap.Token[] wrappedContents
    );
}

contract MultiwrapTest is BaseTest, IMultiwrapData {
    // Target contract
    Multiwrap internal multiwrap;

    // Actors
    Wallet internal tokenOwner;
    Wallet internal wrappedTokenRecipient;

    // Test parameters
    string internal uriForWrappedToken = "ipfs://wrappedNFT";
    IMultiwrap.Token[] internal wrappedContents;

    uint256 internal erc721TokenId = 0;
    uint256 internal erc1155TokenId = 0;
    uint256 internal erc1155Amount = 50;
    uint256 internal erc20Amount = 100 ether;

    //  =====   Set up  =====
    function setUp() public override {
        super.setUp();

        // Get Multiwrap contract.
        multiwrap = Multiwrap(getContract("Multiwrap"));

        // Get test actors.
        tokenOwner = new Wallet();
        wrappedTokenRecipient = new Wallet();

        // Grant MINTER_ROLE to `tokenOwner`
        vm.prank(deployer);
        multiwrap.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        // Mint mock ERC20/721/1155 tokens to `tokenOwner`
        erc20.mint(address(tokenOwner), erc20Amount);
        erc721.mint(address(tokenOwner), 1);
        erc1155.mint(address(tokenOwner), erc1155TokenId, erc1155Amount);

        // Allow Multiwrap to transfer tokens.
        tokenOwner.setAllowanceERC20(address(erc20), address(multiwrap), erc20Amount);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(multiwrap), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(multiwrap), true);

        // Prepare wrapped contents.
        wrappedContents.push(IMultiwrap.Token({
            assetContract: address(erc20),
            tokenType: IMultiwrap.TokenType.ERC20,
            tokenId: 0,
            amount: erc20Amount
        }));
        wrappedContents.push(IMultiwrap.Token({
            assetContract: address(erc721),
            tokenType: IMultiwrap.TokenType.ERC721,
            tokenId: erc721TokenId,
            amount: 1
        }));
        wrappedContents.push(IMultiwrap.Token({
            assetContract: address(erc1155),
            tokenType: IMultiwrap.TokenType.ERC1155,
            tokenId: erc1155TokenId,
            amount: erc1155Amount
        }));
    }

    //  =====   Initial state   =====

    function testInitialState() public {
        (address recipient, uint256 bps) = multiwrap.getDefaultRoyaltyInfo();
        assertTrue(recipient == royaltyRecipient && bps == royaltyBps);

        assertEq(multiwrap.contractURI(), CONTRACT_URI);
        assertEq(multiwrap.name(), NAME);
        assertEq(multiwrap.symbol(), SYMBOL);
        assertEq(multiwrap.nextTokenIdToMint(), 0);

        assertEq(multiwrap.owner(), deployer);
        assertTrue(multiwrap.hasRole(multiwrap.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(multiwrap.hasRole(keccak256("MINTER_ROLE"), deployer));
        assertTrue(multiwrap.hasRole(keccak256("TRANSFER_ROLE"), deployer));
    }

    //  =====   Functionality tests   =====

    /// @dev Test `wrap`
    function test_wrap() public {

        assertEq(erc20.balanceOf(address(tokenOwner)), erc20Amount);
        assertEq(erc721.ownerOf(erc721TokenId), address(tokenOwner));
        assertEq(erc1155.balanceOf(address(tokenOwner), erc1155TokenId), erc1155Amount);

        assertEq(erc20.balanceOf(address(multiwrap)), 0);
        assertEq(erc1155.balanceOf(address(multiwrap), erc1155TokenId), 0);

        uint256 tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));

        assertEq(multiwrap.tokenURI(tokenIdOfWrapped), uriForWrappedToken);
        assertEq(multiwrap.ownerOf(tokenIdOfWrapped), address(wrappedTokenRecipient));

        assertEq(erc20.balanceOf(address(multiwrap)), erc20Amount);
        assertEq(erc721.ownerOf(erc721TokenId), address(multiwrap));
        assertEq(erc1155.balanceOf(address(multiwrap), erc1155TokenId), erc1155Amount);

        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc1155.balanceOf(address(tokenOwner), erc1155TokenId), 0);
    }

    function test_wrap_revert_insufficientBalance1155() public {
        tokenOwner.burnERC1155(address(erc1155), erc1155TokenId, erc1155Amount);

        vm.expectRevert("ERC1155: insufficient balance for transfer");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function test_wrap_revert_insufficientBalance721() public {
        tokenOwner.burnERC721(address(erc721), erc721TokenId);

        vm.expectRevert("ERC721: operator query for nonexistent token");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function test_wrap_revert_insufficientBalance20() public {
        tokenOwner.burnERC20(address(erc20), 1);

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function test_wrap_revert_unapprovedTransfer1155() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(multiwrap), false);

        vm.expectRevert("ERC1155: caller is not owner nor approved");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function test_wrap_revert_unapprovedTransfer721() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(multiwrap), false);

        vm.expectRevert("ERC721: transfer caller is not owner nor approved");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function test_wrap_revert_unapprovedTransfer20() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(multiwrap), 0);

        vm.expectRevert("ERC20: insufficient allowance");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    function test_wrap_emit_TokensWrapped() public {
        uint256 tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        IMultiwrap.Token[] memory contents = new IMultiwrap.Token[](wrappedContents.length);
        for(uint256 i = 0; i < wrappedContents.length; i += 1) {
            contents[i] = wrappedContents[i];
        }

        vm.expectEmit(true, true, true, true);
        emit TokensWrapped(address(tokenOwner), address(wrappedTokenRecipient), tokenIdOfWrapped, contents);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));
    }

    /// @dev Test `unwrap`


    function test_unwrap() public {
        uint256 tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));

        assertEq(multiwrap.ownerOf(tokenIdOfWrapped), address(wrappedTokenRecipient));

        assertEq(erc20.balanceOf(address(multiwrap)), erc20Amount);
        assertEq(erc721.ownerOf(erc721TokenId), address(multiwrap));
        assertEq(erc1155.balanceOf(address(multiwrap), erc1155TokenId), erc1155Amount);

        assertEq(erc20.balanceOf(address(wrappedTokenRecipient)), 0);
        assertEq(erc1155.balanceOf(address(wrappedTokenRecipient), erc1155TokenId), 0);

        vm.prank(address(wrappedTokenRecipient));
        multiwrap.unwrap(tokenIdOfWrapped, address(wrappedTokenRecipient));

        assertEq(erc20.balanceOf(address(wrappedTokenRecipient)), erc20Amount);
        assertEq(erc721.ownerOf(erc721TokenId), address(wrappedTokenRecipient));
        assertEq(erc1155.balanceOf(address(wrappedTokenRecipient), erc1155TokenId), erc1155Amount);

        assertEq(erc20.balanceOf(address(multiwrap)), 0);
        assertEq(erc1155.balanceOf(address(multiwrap), erc1155TokenId), 0);
    }

    function test_unwrap_revert_invalidTokenId() public {
        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));

        uint256 invalidId = multiwrap.nextTokenIdToMint();

        vm.expectRevert("invalid tokenId");

        vm.prank(address(wrappedTokenRecipient));
        multiwrap.unwrap(invalidId, address(wrappedTokenRecipient));
    }


    function test_unwrap_emit_Unwrapped() public {
        uint256 tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, uriForWrappedToken, address(wrappedTokenRecipient));

        IMultiwrap.Token[] memory contents = new IMultiwrap.Token[](wrappedContents.length);
        for(uint256 i = 0; i < wrappedContents.length; i += 1) {
            contents[i] = wrappedContents[i];
        }

        vm.expectEmit(true, true, true, true);
        emit TokensUnwrapped(address(wrappedTokenRecipient), address(wrappedTokenRecipient), tokenIdOfWrapped, contents);

        vm.prank(address(wrappedTokenRecipient));
        multiwrap.unwrap(tokenIdOfWrapped, address(wrappedTokenRecipient));
    }
}
