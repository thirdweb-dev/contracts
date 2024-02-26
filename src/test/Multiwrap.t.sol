// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Multiwrap } from "contracts/prebuilts/multiwrap/Multiwrap.sol";
import { ITokenBundle } from "contracts/extension/interface/ITokenBundle.sol";
import { CurrencyTransferLib } from "contracts/lib/CurrencyTransferLib.sol";

// Test imports
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Strings } from "contracts/lib/Strings.sol";
import { Wallet } from "./utils/Wallet.sol";
import "./utils/BaseTest.sol";

contract MultiwrapReentrant is MockERC20, ITokenBundle {
    Multiwrap internal multiwrap;
    uint256 internal tokenIdOfWrapped = 0;

    constructor(address payable _multiwrap) {
        multiwrap = Multiwrap(_multiwrap);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        multiwrap.unwrap(0, address(this));
        return super.transferFrom(from, to, amount);
    }
}

contract MultiwrapTest is BaseTest {
    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(
        address indexed wrapper,
        address indexed recipientOfWrappedToken,
        uint256 indexed tokenIdOfWrappedToken,
        ITokenBundle.Token[] wrappedContents
    );

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed unwrapper,
        address indexed recipientOfWrappedContents,
        uint256 indexed tokenIdOfWrappedToken
    );

    /*///////////////////////////////////////////////////////////////
                                Setup
    //////////////////////////////////////////////////////////////*/

    Multiwrap internal multiwrap;

    Wallet internal tokenOwner;
    string internal uriForWrappedToken;
    ITokenBundle.Token[] internal wrappedContent;

    function setUp() public override {
        super.setUp();

        // Get target contract
        multiwrap = Multiwrap(payable(getContract("Multiwrap")));

        // Set test vars
        tokenOwner = getWallet();
        uriForWrappedToken = "ipfs://baseURI/";

        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 10 ether
            })
        );
        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );

        // Mint tokens-to-wrap to `tokenOwner`
        erc20.mint(address(tokenOwner), 10 ether);
        erc721.mint(address(tokenOwner), 1);
        erc1155.mint(address(tokenOwner), 0, 100);

        // Token owner approves `Multiwrap` to transfer tokens.
        tokenOwner.setAllowanceERC20(address(erc20), address(multiwrap), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(multiwrap), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(multiwrap), true);

        // Grant MINTER_ROLE / requisite wrapping permissions to `tokenOwer`
        vm.prank(deployer);
        multiwrap.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc.
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Tests whether contract revert when a non-holder renounces a role.
     */
    function test_revert_nonHolder_renounceRole() public {
        address caller = address(0x123);
        bytes32 role = keccak256("MINTER_ROLE");

        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, caller, role));

        multiwrap.renounceRole(role, caller);
    }

    /**
     *  note: Tests whether contract revert when a role admin revokes a role for a non-holder.
     */
    function test_revert_revokeRoleForNonHolder() public {
        address target = address(0x123);
        bytes32 role = keccak256("MINTER_ROLE");

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, target, role));

        multiwrap.revokeRole(role, target);
    }

    /**
     *      Unit tests for relevant functions:
     *      - `wrap`
     *      - `unwrap`
     */

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `wrap`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; token owner calls `wrap` to wrap owned tokens.
     */
    function test_state_wrap() public {
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        assertEq(expectedIdForWrappedToken + 1, multiwrap.nextTokenIdToMint());

        ITokenBundle.Token[] memory contentsOfWrappedToken = multiwrap.getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, wrappedContent.length);
        for (uint256 i = 0; i < contentsOfWrappedToken.length; i += 1) {
            assertEq(contentsOfWrappedToken[i].assetContract, wrappedContent[i].assetContract);
            assertEq(uint256(contentsOfWrappedToken[i].tokenType), uint256(wrappedContent[i].tokenType));
            assertEq(contentsOfWrappedToken[i].tokenId, wrappedContent[i].tokenId);
            assertEq(contentsOfWrappedToken[i].totalAmount, wrappedContent[i].totalAmount);
        }

        assertEq(uriForWrappedToken, multiwrap.tokenURI(expectedIdForWrappedToken));
    }

    /*
     *  note: Testing state changes; token owner calls `wrap` to wrap native tokens.
     */
    function test_state_wrap_nativeTokens() public {
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        ITokenBundle.Token[] memory nativeTokenContentToWrap = new ITokenBundle.Token[](1);

        vm.deal(address(tokenOwner), 100 ether);
        nativeTokenContentToWrap[0] = ITokenBundle.Token({
            assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 10 ether
        });

        vm.prank(address(tokenOwner));
        multiwrap.wrap{ value: 10 ether }(nativeTokenContentToWrap, uriForWrappedToken, recipient);

        assertEq(expectedIdForWrappedToken + 1, multiwrap.nextTokenIdToMint());

        ITokenBundle.Token[] memory contentsOfWrappedToken = multiwrap.getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, nativeTokenContentToWrap.length);
        for (uint256 i = 0; i < contentsOfWrappedToken.length; i += 1) {
            assertEq(contentsOfWrappedToken[i].assetContract, nativeTokenContentToWrap[i].assetContract);
            assertEq(uint256(contentsOfWrappedToken[i].tokenType), uint256(nativeTokenContentToWrap[i].tokenType));
            assertEq(contentsOfWrappedToken[i].tokenId, nativeTokenContentToWrap[i].tokenId);
            assertEq(contentsOfWrappedToken[i].totalAmount, nativeTokenContentToWrap[i].totalAmount);
        }

        assertEq(uriForWrappedToken, multiwrap.tokenURI(expectedIdForWrappedToken));
    }

    /**
     *  note: Testing state changes; token owner calls `wrap` to wrap owned tokens.
     *        Only assets with ASSET_ROLE can be wrapped.
     */
    function test_state_wrap_withAssetRoleRestriction() public {
        // ===== setup =====

        vm.startPrank(deployer);
        multiwrap.revokeRole(keccak256("ASSET_ROLE"), address(0));

        for (uint256 i = 0; i < wrappedContent.length; i += 1) {
            multiwrap.grantRole(keccak256("ASSET_ROLE"), wrappedContent[i].assetContract);
        }

        vm.stopPrank();

        // ===== target test content =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        assertEq(expectedIdForWrappedToken + 1, multiwrap.nextTokenIdToMint());

        ITokenBundle.Token[] memory contentsOfWrappedToken = multiwrap.getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, wrappedContent.length);
        for (uint256 i = 0; i < contentsOfWrappedToken.length; i += 1) {
            assertEq(contentsOfWrappedToken[i].assetContract, wrappedContent[i].assetContract);
            assertEq(uint256(contentsOfWrappedToken[i].tokenType), uint256(wrappedContent[i].tokenType));
            assertEq(contentsOfWrappedToken[i].tokenId, wrappedContent[i].tokenId);
            assertEq(contentsOfWrappedToken[i].totalAmount, wrappedContent[i].totalAmount);
        }

        assertEq(uriForWrappedToken, multiwrap.tokenURI(expectedIdForWrappedToken));
    }

    /**
     *  note: Testing event emission; token owner calls `wrap` to wrap owned tokens.
     */
    function test_event_wrap_TokensWrapped() public {
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));

        vm.expectEmit(true, true, true, true);
        emit TokensWrapped(address(tokenOwner), recipient, expectedIdForWrappedToken, wrappedContent);

        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing token balances; token owner calls `wrap` to wrap owned tokens.
     */
    function test_balances_wrap() public {
        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 10 ether);
        assertEq(erc20.balanceOf(address(multiwrap)), 0);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(tokenOwner));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 100);
        assertEq(erc1155.balanceOf(address(multiwrap), 0), 0);

        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(multiwrap)), 10 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(multiwrap));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(multiwrap), 0), 100);

        // Multiwrap wrapped token balance
        assertEq(multiwrap.ownerOf(expectedIdForWrappedToken), recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap owned tokens.
     */
    function test_revert_wrap_reentrancy() public {
        MultiwrapReentrant reentrant = new MultiwrapReentrant(payable(address(multiwrap)));
        ITokenBundle.Token[] memory reentrantContentToWrap = new ITokenBundle.Token[](1);

        reentrant.mint(address(tokenOwner), 10 ether);
        reentrantContentToWrap[0] = ITokenBundle.Token({
            assetContract: address(reentrant),
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 10 ether
        });

        tokenOwner.setAllowanceERC20(address(reentrant), address(multiwrap), 10 ether);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ReentrancyGuard: reentrant call");
        multiwrap.wrap(reentrantContentToWrap, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap owned tokens.
     *        Only assets with ASSET_ROLE can be wrapped, but assets being wrapped don't have that role.
     */
    function test_revert_wrap_access_ASSET_ROLE() public {
        vm.prank(deployer);
        multiwrap.revokeRole(keccak256("ASSET_ROLE"), address(0));

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(erc20),
                keccak256("ASSET_ROLE")
            )
        );
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap owned tokens, without MINTER_ROLE.
     */
    function test_revert_wrap_access_MINTER_ROLE() public {
        vm.prank(address(tokenOwner));
        multiwrap.renounceRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(tokenOwner),
                keccak256("MINTER_ROLE")
            )
        );
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` with insufficient value when wrapping native tokens.
     */
    function test_revert_wrap_nativeTokens_insufficientValue() public {
        address recipient = address(0x123);

        ITokenBundle.Token[] memory nativeTokenContentToWrap = new ITokenBundle.Token[](1);

        vm.deal(address(tokenOwner), 100 ether);
        nativeTokenContentToWrap[0] = ITokenBundle.Token({
            assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 10 ether
        });

        vm.prank(address(tokenOwner));
        vm.expectRevert(
            abi.encodeWithSelector(CurrencyTransferLib.CurrencyTransferLibMismatchedValue.selector, 0, 10 ether)
        );
        multiwrap.wrap(nativeTokenContentToWrap, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap native tokens, but with multiple instances in `tokensToWrap` array.
     */
    function test_balances_wrap_nativeTokens_multipleInstances() public {
        address recipient = address(0x123);

        ITokenBundle.Token[] memory nativeTokenContentToWrap = new ITokenBundle.Token[](2);

        vm.deal(address(tokenOwner), 100 ether);
        nativeTokenContentToWrap[0] = ITokenBundle.Token({
            assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 5 ether
        });
        nativeTokenContentToWrap[1] = ITokenBundle.Token({
            assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 5 ether
        });

        vm.prank(address(tokenOwner));
        multiwrap.wrap{ value: 10 ether }(nativeTokenContentToWrap, uriForWrappedToken, recipient);

        assertEq(weth.balanceOf(address(multiwrap)), 10 ether);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC20 tokens.
     */
    function test_revert_wrap_notOwner_ERC20() public {
        tokenOwner.transferERC20(address(erc20), address(0x12), 10 ether);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC721 tokens.
     */
    function test_revert_wrap_notOwner_ERC721() public {
        tokenOwner.transferERC721(address(erc721), address(0x12), 0);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC1155 tokens.
     */
    function test_revert_wrap_notOwner_ERC1155() public {
        tokenOwner.transferERC1155(address(erc1155), address(0x12), 0, 100, "");

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC1155: insufficient balance for transfer");
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC20 tokens.
     */
    function test_revert_wrap_notApprovedTransfer_ERC20() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(multiwrap), 0);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC20: insufficient allowance");
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC721 tokens.
     */
    function test_revert_wrap_notApprovedTransfer_ERC721() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(multiwrap), false);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `wrap` to wrap un-owned ERC1155 tokens.
     */
    function test_revert_wrap_notApprovedTransfer_ERC1155() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(multiwrap), false);

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("ERC1155: caller is not token owner or approved");
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    function test_revert_wrap_noTokensToWrap() public {
        ITokenBundle.Token[] memory emptyContent;

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert("!Tokens");
        multiwrap.wrap(emptyContent, uriForWrappedToken, recipient);
    }

    function test_revert_wrap_nativeTokens_insufficientValueProvided_multipleInstances() public {
        address recipient = address(0x123);

        ITokenBundle.Token[] memory nativeTokenContentToWrap = new ITokenBundle.Token[](2);

        vm.deal(address(tokenOwner), 100 ether);
        vm.deal(address(multiwrap), 10 ether);
        nativeTokenContentToWrap[0] = ITokenBundle.Token({
            assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 10 ether
        });
        nativeTokenContentToWrap[1] = ITokenBundle.Token({
            assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 10 ether
        });

        vm.prank(address(tokenOwner));
        vm.expectRevert(
            abi.encodeWithSelector(CurrencyTransferLib.CurrencyTransferLibMismatchedValue.selector, 10 ether, 20 ether)
        );
        multiwrap.wrap{ value: 10 ether }(nativeTokenContentToWrap, uriForWrappedToken, recipient);

        assertEq(address(multiwrap).balance, 10 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `unwrap`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; wrapped token owner calls `unwrap` to unwrap underlying tokens.
     */
    function test_state_unwrap() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(recipient);
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);

        vm.expectRevert("ERC721: invalid token ID");
        multiwrap.ownerOf(expectedIdForWrappedToken);

        assertEq(uriForWrappedToken, multiwrap.tokenURI(expectedIdForWrappedToken));
        assertEq(0, multiwrap.getTokenCountOfBundle(expectedIdForWrappedToken));

        ITokenBundle.Token[] memory contentsOfWrappedToken = multiwrap.getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, 0);
    }

    /**
     *  note: Testing state changes; wrapped token owner calls `unwrap` to unwrap native tokens.
     */
    function test_state_unwrap_nativeTokens() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        ITokenBundle.Token[] memory nativeTokenContentToWrap = new ITokenBundle.Token[](1);

        vm.deal(address(tokenOwner), 100 ether);
        nativeTokenContentToWrap[0] = ITokenBundle.Token({
            assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 10 ether
        });

        vm.prank(address(tokenOwner));
        multiwrap.wrap{ value: 10 ether }(nativeTokenContentToWrap, uriForWrappedToken, recipient);

        // ===== target test content =====

        assertEq(address(recipient).balance, 0);

        vm.prank(recipient);
        // it fails here and it shouldn't
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);

        assertEq(address(recipient).balance, 10 ether);
    }

    /**
     *  note: Testing state changes; wrapped token owner calls `unwrap` to unwrap underlying tokens.
     */
    function test_state_unwrap_approvedCaller() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        address approvedCaller = address(0x12);

        vm.prank(recipient);
        multiwrap.setApprovalForAll(approvedCaller, true);

        vm.prank(approvedCaller);
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);

        vm.expectRevert("ERC721: invalid token ID");
        multiwrap.ownerOf(expectedIdForWrappedToken);

        assertEq(uriForWrappedToken, multiwrap.tokenURI(expectedIdForWrappedToken));
        assertEq(0, multiwrap.getTokenCountOfBundle(expectedIdForWrappedToken));

        ITokenBundle.Token[] memory contentsOfWrappedToken = multiwrap.getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, 0);
    }

    function test_event_unwrap_TokensUnwrapped() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(recipient);

        vm.expectEmit(true, true, true, true);
        emit TokensUnwrapped(recipient, recipient, expectedIdForWrappedToken);

        multiwrap.unwrap(expectedIdForWrappedToken, recipient);
    }

    function test_balances_unwrap() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        // ERC20 balance
        assertEq(erc20.balanceOf(address(recipient)), 0);
        assertEq(erc20.balanceOf(address(multiwrap)), 10 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(multiwrap));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(recipient), 0), 0);
        assertEq(erc1155.balanceOf(address(multiwrap), 0), 100);

        vm.prank(recipient);
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(recipient)), 10 ether);
        assertEq(erc20.balanceOf(address(multiwrap)), 0);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(recipient));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(recipient), 0), 100);
        assertEq(erc1155.balanceOf(address(multiwrap), 0), 0);
    }

    function test_revert_unwrap_invalidTokenId() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(recipient);
        vm.expectRevert("wrapped NFT DNE.");
        multiwrap.unwrap(expectedIdForWrappedToken + 1, recipient);
    }

    function test_revert_unwrap_unapprovedCaller() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(address(0x12));
        vm.expectRevert("caller not approved for unwrapping.");
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);
    }

    function test_revert_unwrap_notOwner() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(recipient);
        multiwrap.transferFrom(recipient, address(0x12), 0);

        vm.prank(recipient);
        vm.expectRevert("caller not approved for unwrapping.");
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);
    }

    function test_revert_unwrap_access_UNWRAP_ROLE() public {
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(deployer);
        multiwrap.revokeRole(keccak256("UNWRAP_ROLE"), address(0));

        vm.prank(recipient);
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                recipient,
                keccak256("UNWRAP_ROLE")
            )
        );
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);
    }

    /**
     *      Fuzz testing:
     *      - Wrapping and unwrapping arbitrary kinds of tokens
     */

    uint256 internal constant MAX_TOKENS = 1000;

    function getTokensToWrap(uint256 x) internal returns (ITokenBundle.Token[] memory tokensToWrap) {
        uint256 len = x % MAX_TOKENS;
        tokensToWrap = new ITokenBundle.Token[](len);

        for (uint256 i = 0; i < len; i += 1) {
            uint256 random = uint256(keccak256(abi.encodePacked(len + i))) % MAX_TOKENS;
            uint256 selector = random % 3;

            if (selector == 0) {
                tokensToWrap[i] = ITokenBundle.Token({
                    assetContract: address(erc20),
                    tokenType: ITokenBundle.TokenType.ERC20,
                    tokenId: 0,
                    totalAmount: random
                });

                erc20.mint(address(tokenOwner), tokensToWrap[i].totalAmount);
            } else if (selector == 1) {
                uint256 tokenId = erc721.nextTokenIdToMint();

                tokensToWrap[i] = ITokenBundle.Token({
                    assetContract: address(erc721),
                    tokenType: ITokenBundle.TokenType.ERC721,
                    tokenId: tokenId,
                    totalAmount: 1
                });

                erc721.mint(address(tokenOwner), 1);
            } else if (selector == 2) {
                tokensToWrap[i] = ITokenBundle.Token({
                    assetContract: address(erc1155),
                    tokenType: ITokenBundle.TokenType.ERC1155,
                    tokenId: random,
                    totalAmount: random
                });

                erc1155.mint(address(tokenOwner), tokensToWrap[i].tokenId, tokensToWrap[i].totalAmount);
            }
        }
    }

    function test_fuzz_state_wrap(uint256 x) public {
        ITokenBundle.Token[] memory tokensToWrap = getTokensToWrap(x);
        if (tokensToWrap.length == 0) {
            return;
        }

        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(tokensToWrap, uriForWrappedToken, recipient);

        assertEq(expectedIdForWrappedToken + 1, multiwrap.nextTokenIdToMint());

        ITokenBundle.Token[] memory contentsOfWrappedToken = multiwrap.getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, tokensToWrap.length);
        for (uint256 i = 0; i < contentsOfWrappedToken.length; i += 1) {
            assertEq(contentsOfWrappedToken[i].assetContract, tokensToWrap[i].assetContract);
            assertEq(uint256(contentsOfWrappedToken[i].tokenType), uint256(tokensToWrap[i].tokenType));
            assertEq(contentsOfWrappedToken[i].tokenId, tokensToWrap[i].tokenId);
            assertEq(contentsOfWrappedToken[i].totalAmount, tokensToWrap[i].totalAmount);
        }

        assertEq(uriForWrappedToken, multiwrap.tokenURI(expectedIdForWrappedToken));
    }

    function test_fuzz_state_unwrap(uint256 x) public {
        // ===== setup: wrap tokens =====

        ITokenBundle.Token[] memory tokensToWrap = getTokensToWrap(x);
        if (tokensToWrap.length == 0) {
            return;
        }

        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(tokensToWrap, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(recipient);
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);

        vm.expectRevert("ERC721: invalid token ID");
        multiwrap.ownerOf(expectedIdForWrappedToken);

        assertEq(uriForWrappedToken, multiwrap.tokenURI(expectedIdForWrappedToken));
        assertEq(0, multiwrap.getTokenCountOfBundle(expectedIdForWrappedToken));

        ITokenBundle.Token[] memory contentsOfWrappedToken = multiwrap.getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, 0);
    }
}
