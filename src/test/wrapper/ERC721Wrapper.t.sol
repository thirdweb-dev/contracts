// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/wrapper/ERC721Wrapper.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import { Wallet } from "../utils/Wallet.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract ERC721WrapperTest is BaseTest {
    /// @dev Emitted when token is wrapped.
    event TokenWrapped(address indexed wrapper, address indexed recipient, uint256 indexed tokenIdOfWrappedToken);

    /// @dev Emitted when token is unwrapped.
    event TokenUnwrapped(address indexed unwrapper, address indexed recipient, uint256 indexed tokenIdOfWrappedToken);

    /*///////////////////////////////////////////////////////////////
                                Setup
    //////////////////////////////////////////////////////////////*/

    ERC721Wrapper internal wrapper;

    Wallet internal tokenOwner;

    function setUp() public override {
        super.setUp();

        // Get target contract
        wrapper = ERC721Wrapper(payable(getContract("ERC721Wrapper")));

        // Set test vars
        tokenOwner = getWallet();

        // Mint tokens-to-wrap to `tokenOwner`
        erc721.mint(address(tokenOwner), 1);

        tokenOwner.setApprovalForAllERC721(address(erc721), address(wrapper), true);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `wrap`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; token owner calls `wrap` to wrap owned tokens.
     */
    function test_state_wrap() public {
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id);

        assertEq(erc721.ownerOf(id), address(wrapper));
        assertEq(wrapper.ownerOf(id), address(recipient));
        assertEq(erc721.tokenURI(id), wrapper.tokenURI(id));
    }

    /**
     *  note: Testing event emission; token owner calls `wrap` to wrap owned tokens.
     */
    function test_event_wrap_TokensWrapped() public {
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));

        vm.expectEmit(true, true, true, true);
        emit TokenWrapped(address(tokenOwner), recipient, id);

        wrapper.wrap(recipient, id);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC721 tokens.
     */
    function test_revert_wrap_notOwner_ERC721() public {
        tokenOwner.transferERC721(address(erc721), address(0x12), 0);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        wrapper.wrap(recipient, 0);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC721 tokens.
     */
    function test_revert_wrap_notApprovedTransfer_ERC721() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(wrapper), false);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        wrapper.wrap(recipient, 0);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `unwrap`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; wrapped token owner calls `unwrap` to unwrap underlying tokens.
     */
    function test_state_unwrap() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id);

        assertEq(erc721.ownerOf(id), address(wrapper));
        assertEq(wrapper.ownerOf(id), address(recipient));
        assertEq(erc721.tokenURI(id), wrapper.tokenURI(id));

        // ===== target test content =====

        vm.prank(recipient);
        wrapper.unwrap(recipient, id);

        vm.expectRevert("ERC721: owner query for nonexistent token");
        wrapper.ownerOf(id);

        assertEq(erc721.ownerOf(id), address(recipient));
    }

    function test_event_unwrap_TokensUnwrapped() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id);

        // ===== target test content =====

        vm.prank(recipient);

        vm.expectEmit(true, true, true, true);
        emit TokenUnwrapped(recipient, recipient, id);

        wrapper.unwrap(recipient, id);
    }

    function test_revert_unwrap_invalidTokenId() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id);

        // ===== target test content =====

        vm.prank(recipient);
        vm.expectRevert("ERC721: operator query for nonexistent token");
        wrapper.unwrap(recipient, id + 1);
    }

    function test_revert_unwrap_unapprovedCaller() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id);

        // ===== target test content =====

        vm.prank(address(0x12));
        vm.expectRevert("caller not approved for unwrapping.");
        wrapper.unwrap(recipient, id);
    }

    function test_revert_unwrap_notOwner() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id);

        // ===== target test content =====

        vm.prank(recipient);
        wrapper.transferFrom(recipient, address(0x12), 0);

        vm.prank(recipient);
        vm.expectRevert("caller not approved for unwrapping.");
        wrapper.unwrap(recipient, id);
    }
}
