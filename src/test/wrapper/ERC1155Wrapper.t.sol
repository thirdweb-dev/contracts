// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/wrapper/ERC1155Wrapper.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import { Wallet } from "../utils/Wallet.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract ERC1155WrapperTest is BaseTest {
    /// @dev Emitted when token is wrapped.
    event TokenWrapped(
        address indexed wrapper,
        address indexed recipient,
        uint256 indexed tokenIdOfWrappedToken,
        uint256 amount
    );

    /// @dev Emitted when token is unwrapped.
    event TokenUnwrapped(
        address indexed unwrapper,
        address indexed recipient,
        uint256 indexed tokenIdOfWrappedToken,
        uint256 amount
    );

    /*///////////////////////////////////////////////////////////////
                                Setup
    //////////////////////////////////////////////////////////////*/

    ERC1155Wrapper internal wrapper;

    Wallet internal tokenOwner;

    function setUp() public override {
        super.setUp();

        // Get target contract
        wrapper = ERC1155Wrapper(payable(getContract("ERC1155Wrapper")));

        // Set test vars
        tokenOwner = getWallet();

        // Mint tokens-to-wrap to `tokenOwner`
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(wrapper), true);
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
        wrapper.wrap(recipient, id, 20);

        assertEq(erc1155.balanceOf(address(wrapper), id), 20);
        assertEq(erc1155.balanceOf(address(tokenOwner), id), 80);
        assertEq(wrapper.balanceOf(recipient, id), 20);
        assertEq(erc1155.uri(0), wrapper.uri(0));
    }

    /**
     *  note: Testing event emission; token owner calls `wrap` to wrap owned tokens.
     */
    function test_event_wrap_TokensWrapped() public {
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));

        vm.expectEmit(true, true, true, true);
        emit TokenWrapped(address(tokenOwner), recipient, id, 20);

        wrapper.wrap(recipient, id, 20);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC721 tokens.
     */
    function test_revert_wrap_notApprovedTransfer_ERC1155() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(wrapper), false);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC1155: caller is not owner nor approved");
        wrapper.wrap(recipient, 0, 20);
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
        wrapper.wrap(recipient, id, 20);

        assertEq(erc1155.balanceOf(address(wrapper), id), 20);
        assertEq(erc1155.balanceOf(address(tokenOwner), id), 80);
        assertEq(wrapper.balanceOf(recipient, id), 20);
        assertEq(erc1155.uri(0), wrapper.uri(0));

        // ===== target test content =====

        vm.prank(recipient);
        wrapper.unwrap(recipient, id, 10);

        assertEq(erc1155.balanceOf(recipient, id), 10);
        assertEq(wrapper.balanceOf(recipient, id), 10);
        assertEq(erc1155.uri(0), wrapper.uri(0));
    }

    function test_event_unwrap_TokensUnwrapped() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id, 20);

        // ===== target test content =====

        vm.prank(recipient);

        vm.expectEmit(true, true, true, true);
        emit TokenUnwrapped(recipient, recipient, id, 10);

        wrapper.unwrap(recipient, id, 10);
    }

    function test_revert_unwrap_invalidTokenId() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id, 20);

        // ===== target test content =====

        vm.prank(recipient);
        vm.expectRevert("ERC1155: caller is not owner nor approved");
        wrapper.wrap(recipient, id + 1, 20);
    }

    function test_revert_unwrap_unapprovedCaller() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id, 20);

        // ===== target test content =====

        vm.prank(address(0x12));
        vm.expectRevert("ERC1155: caller is not owner nor approved");
        wrapper.wrap(recipient, id, 20);
    }

    function test_revert_unwrap_notOwner() public {
        // ===== setup: wrap tokens =====
        uint256 id = 0;
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        wrapper.wrap(recipient, id, 20);

        // ===== target test content =====

        vm.prank(recipient);
        wrapper.safeTransferFrom(recipient, address(0x12), id, 20, "");

        vm.prank(recipient);
        vm.expectRevert("ERC1155: caller is not owner nor approved");
        wrapper.wrap(recipient, id, 20);
    }
}
