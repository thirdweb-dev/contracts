// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target
import "contracts/Multiwrap.sol";

// Test imports
import "./utils/BaseTest.sol";
import "./utils/Wallet.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC1155.sol";
import "contracts/lib/MultiTokenTransferLib.sol";

interface IMultiwrapData {
    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, MultiTokenTransferLib.Bundle wrappedContents);

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed wrapper,
        address sentTo,
        uint256 indexed tokenIdOfShares,
        uint256 sharesUnwrapped,
        MultiTokenTransferLib.Bundle wrappedContents
    );
}

// contract MockERC20Reentrancy is MockERC20 {
//     uint256 targetTokenId;
//     Multiwrap internal multiwrap;

//     bool internal toReenter;

//     constructor(address _multiwrap) MockERC20() {
//         multiwrap = Multiwrap(_multiwrap);
//     }

//     function setToReenter(bool _toReenter) external {
//         toReenter = _toReenter;
//     }

//     function transferFrom(
//         address sender,
//         address recipient,
//         uint256 amount
//     ) public virtual override returns (bool) {
//         if (_msgSender() == address(multiwrap) && toReenter) {
//             multiwrap.unwrap(targetTokenId, amount, msg.sender);
//         } else {
//             _transfer(sender, recipient, amount);

//             uint256 currentAllowance = allowance(sender, _msgSender());
//             require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
//             unchecked {
//                 _approve(sender, _msgSender(), currentAllowance - amount);
//             }
//         }

//         return true;
//     }

//     function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
//         if (_msgSender() == address(multiwrap)) {
//             multiwrap.unwrap(targetTokenId, amount, msg.sender);
//         } else {
//             _transfer(_msgSender(), recipient, amount);
//         }

//         return true;
//     }
// }

contract MultiwrapTest is BaseTest, IMultiwrapData {
    // Target contract
    Multiwrap internal multiwrap;

    // Actors
    Wallet internal tokenOwner;
    Wallet internal nonTokenOwner;
    Wallet internal shareHolder;

    //  =====   Set up  =====

    function setUp() public override {
        super.setUp();

        multiwrap = Multiwrap(getContract("Multiwrap"));

        tokenOwner = new Wallet();
        nonTokenOwner = new Wallet();
        shareHolder = new Wallet();
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

    uint256 internal erc20AmountToWrap = 500 ether;
    uint256[] internal erc721TokensToWrap = [0, 1, 2];
    uint256[] internal erc1155TokensToWrap = [0, 1, 2, 3];
    uint256[] internal erc1155AmountsToWrap = [20, 40, 60, 80];

    MultiTokenTransferLib.Bundle internal wrappedContents;

    function getDefaultWrappedContents() internal view returns (MultiTokenTransferLib.Bundle memory) {
        address[] memory erc1155AssetContracts_ = new address[](1);
        erc1155AssetContracts_[0] = address(erc1155);

        uint256[][] memory erc1155TokensToWrap_ = new uint256[][](1);
        erc1155TokensToWrap_[0] = erc1155TokensToWrap;

        uint256[][] memory erc1155AmountsToWrap_ = new uint256[][](1);
        erc1155AmountsToWrap_[0] = erc1155AmountsToWrap;

        address[] memory erc721AssetContracts_ = new address[](1);
        erc721AssetContracts_[0] = address(erc721);

        uint256[][] memory erc721TokensToWrap_ = new uint256[][](1);
        erc721TokensToWrap_[0] = erc721TokensToWrap;

        address[] memory erc20AssetContracts_ = new address[](1);
        erc20AssetContracts_[0] = address(erc20);

        uint256[] memory erc20AmountsToWrap_ = new uint256[](1);
        erc20AmountsToWrap_[0] = erc20AmountToWrap;

        return
            MultiTokenTransferLib.Bundle({
                erc1155AssetContracts: erc1155AssetContracts_,
                erc1155TokensToWrap: erc1155TokensToWrap_,
                erc1155AmountsToWrap: erc1155AmountsToWrap_,
                erc721AssetContracts: erc721AssetContracts_,
                erc721TokensToWrap: erc721TokensToWrap_,
                erc20AssetContracts: erc20AssetContracts_,
                erc20AmountsToWrap: erc20AmountsToWrap_
            });
    }

    function _setup_wrap() internal {

        erc20.mint(address(tokenOwner), erc20AmountToWrap);
        erc721.mint(address(tokenOwner), erc721TokensToWrap.length);
        erc1155.mintBatch(address(tokenOwner), erc1155TokensToWrap, erc1155AmountsToWrap);
        
        tokenOwner.setAllowance20(address(erc20), address(multiwrap), erc20AmountToWrap);
        tokenOwner.setApprovalForAll721(address(erc721), address(multiwrap), true);
        tokenOwner.setApprovalForAll1155(address(erc1155), address(multiwrap), true);

        wrappedContents = getDefaultWrappedContents();
    }

    

    /// @dev Test `wrap`
    function test_wrap() public {
        _setup_wrap();

        assertBal20Strict(address(erc20), address(tokenOwner), erc20AmountToWrap);
        assertBal721(address(erc721), address(tokenOwner), erc721TokensToWrap, true);
        assertBal1155Strict(
            address(erc1155),
            address(tokenOwner), 
            erc1155TokensToWrap,
            erc1155AmountsToWrap
        );

        assertBal20Strict(address(erc20), address(multiwrap), 0);
        assertBal721(address(erc721), address(multiwrap), erc721TokensToWrap, false);
        assertBal1155Strict(
            address(erc1155),
            address(multiwrap), 
            new uint256[](wrappedContents.erc1155TokensToWrap.length),
            new uint256[](wrappedContents.erc1155AmountsToWrap.length)
        );

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        uint256 tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);

        assertEq(multiwrap.uri(tokenIdOfWrapped), uriForShares);
        assertEq(multiwrap.totalSupply(tokenIdOfWrapped), sharesToMint);
        assertEq(multiwrap.totalShares(tokenIdOfWrapped), sharesToMint);
        assertEq(multiwrap.balanceOf(address(tokenOwner), tokenIdOfWrapped), sharesToMint);

        assertBal20Strict(address(erc20), address(multiwrap), erc20AmountToWrap);
        assertBal721(address(erc721), address(multiwrap), erc721TokensToWrap, true);
        assertBal1155Strict(
            address(erc1155),
            address(multiwrap), 
            erc1155TokensToWrap,
            erc1155AmountsToWrap
        );

        assertBal20Strict(address(erc20), address(tokenOwner), 0);
        assertBal721(address(erc721), address(tokenOwner), erc721TokensToWrap, false);
        assertBal1155Strict(
            address(erc1155),
            address(tokenOwner), 
            new uint256[](wrappedContents.erc1155TokensToWrap.length),
            new uint256[](wrappedContents.erc1155AmountsToWrap.length)
        );
    }

    function test_wrap_revert_insufficientBalance1155() public {
        _setup_wrap();

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenOwner.burn1155(address(erc1155), 0, 1);

        vm.expectRevert("ERC1155: insufficient balance for transfer");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_insufficientBalance721() public {
        _setup_wrap();

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenOwner.burn721(address(erc721), 0);

        vm.expectRevert("ERC721: operator query for nonexistent token");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_insufficientBalance20() public {
        _setup_wrap();

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenOwner.burn20(address(erc20), 1);

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_unapprovedTransfer1155() public {
        _setup_wrap();

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenOwner.setApprovalForAll1155(address(erc1155), address(multiwrap), false);

        vm.expectRevert("ERC1155: caller is not owner nor approved");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_unapprovedTransfer721() public {
        _setup_wrap();

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenOwner.setApprovalForAll721(address(erc721), address(multiwrap), false);

        vm.expectRevert("ERC721: transfer caller is not owner nor approved");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_unapprovedTransfer20() public {
        _setup_wrap();

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenOwner.setAllowance20(address(erc20), address(multiwrap), 0);

        vm.expectRevert("ERC20: insufficient allowance");

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_emit_Wrapped() public {
        _setup_wrap();

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";
        uint256 tokenIdExpected = multiwrap.nextTokenIdToMint();

        vm.expectEmit(true, true, false, true);
        emit TokensWrapped(address(tokenOwner), tokenIdExpected, wrappedContents);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    // /// @dev Test `unwrap`

    // function _setup_unwrap() internal returns (uint256 tokenIdOfWrapped) {
    //     _setup_wrap();

    //     uint256 sharesToMint = 10;
    //     string memory uriForShares = "ipfs://shares";

    //     tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

    //     vm.prank(tokenOwner);
    //     multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    // }

    // function test_unwrap() public {
    //     uint256 tokenIdOfWrapped = _setup_unwrap();
    //     uint256 ownerBalBeforeERC20 = erc20.balanceOf(tokenOwner);

    //     vm.prank(tokenOwner);
    //     multiwrap.unwrap(tokenIdOfWrapped, 1, tokenOwner);

    //     assertEq(multiwrap.totalSupply(tokenIdOfWrapped), 0);
    //     assertEq(multiwrap.balanceOf(tokenOwner, tokenIdOfWrapped), 0);

    //     assertEq(erc20.balanceOf(tokenOwner), erc20AmountToWrap + ownerBalBeforeERC20);
    //     for (uint256 i = 0; i < wrappedContents.erc721AssetContracts.length; i += 1) {
    //         address asset = wrappedContents.erc721AssetContracts[i];
    //         for (uint256 j = 0; j < wrappedContents.erc721TokensToWrap.length; j += 1) {
    //             uint256 tokenId = wrappedContents.erc721TokensToWrap[i][j];
    //             assertEq(MockERC721(asset).ownerOf(tokenId), tokenOwner);
    //         }
    //     }

    //     for (uint256 i = 0; i < wrappedContents.erc1155AssetContracts.length; i += 1) {
    //         address asset = wrappedContents.erc1155AssetContracts[i];
    //         for (uint256 j = 0; j < erc1155TokensToWrap.length; j += 1) {
    //             uint256 tokenId = wrappedContents.erc1155TokensToWrap[i][j];
    //             uint256 wrappedAmount = wrappedContents.erc1155AmountsToWrap[i][j];
    //             assertEq(MockERC1155(asset).balanceOf(address(multiwrap), tokenId), 0);
    //             assertEq(MockERC1155(asset).balanceOf(tokenOwner, tokenId), wrappedAmount);
    //         }
    //     }
    // }

    // function test_unwrap_revert_invalidTokenId() public {
    //     _setup_unwrap();

    //     uint256 invalidId = multiwrap.nextTokenIdToMint();

    //     vm.expectRevert("invalid tokenId");

    //     vm.prank(tokenOwner);
    //     multiwrap.unwrap(invalidId, 1, tokenOwner);
    // }

    // function test_unwrap_revert_insufficientShares() public {
    //     uint256 tokenIdOfWrapped = _setup_unwrap();

    //     vm.prank(tokenOwner);
    //     multiwrap.safeTransferFrom(tokenOwner, deployer, tokenIdOfWrapped, 1, "");

    //     vm.expectRevert("must own all shares to unwrap");

    //     vm.prank(tokenOwner);
    //     multiwrap.unwrap(tokenIdOfWrapped, 1, tokenOwner);
    // }

    // function test_unwrap_emit_Unwrapped() public {
    //     uint256 tokenIdOfWrapped = _setup_unwrap();
    //     uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);

    //     vm.expectEmit(true, true, false, true);
    //     emit TokensUnwrapped(tokenOwner, tokenIdOfWrapped, totalShares, wrappedContents);

    //     vm.prank(tokenOwner);
    //     multiwrap.unwrap(tokenIdOfWrapped, totalShares, tokenOwner);
    // }

    // //  =====   Attack vectors  =====
    // /**
    //  *      - Re-entrancy on `unwrap` and `unwrapByShares`.
    //  *      - `unwrapByShares` should always honor the correct
    //  *         amount of shares.
    //  */

    // MockERC20Reentrancy erc20Reentrancy;

    // function _setup_unwrap_reentrancy() internal returns (uint256 tokenIdOfWrapped) {
    //     vm.startPrank(tokenOwner);

    //     erc20Reentrancy = new MockERC20Reentrancy(address(multiwrap));
    //     erc20Reentrancy.mint(tokenOwner, erc20AmountToWrap);

    //     erc721 = new MockERC721();
    //     erc721.mint(erc721TokensToWrap.length);

    //     erc1155 = new MockERC1155();
    //     erc1155.mintBatch(tokenOwner, erc1155TokensToWrap, erc1155AmountsToWrap, "");

    //     vm.stopPrank();

    //     MultiTokenTransferLib.Bundle memory onlyERC20Wrapped = _get_onlyWrapERC20Reentrancy();

    //     setApproval20(
    //         onlyERC20Wrapped.erc20AssetContracts,
    //         onlyERC20Wrapped.erc20AmountsToWrap,
    //         true,
    //         tokenOwner,
    //         address(multiwrap)
    //     );

    //     uint256 sharesToMint = 10;
    //     string memory uriForShares = "ipfs://shares";

    //     tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

    //     vm.prank(tokenOwner);
    //     multiwrap.wrap(onlyERC20Wrapped, sharesToMint, uriForShares);
    // }

    // function _get_onlyWrapERC20Reentrancy() internal view returns (MultiTokenTransferLib.Bundle memory onlyERC20Wrapped) {
    //     address[] memory erc1155AssetContracts_;
    //     uint256[][] memory erc1155TokensToWrap_;
    //     uint256[][] memory erc1155AmountsToWrap_;

    //     address[] memory erc721AssetContracts_;
    //     uint256[][] memory erc721TokensToWrap_;

    //     address[] memory erc20AssetContracts_ = new address[](1);
    //     erc20AssetContracts_[0] = address(erc20Reentrancy);

    //     uint256[] memory erc20AmountsToWrap_ = new uint256[](1);
    //     erc20AmountsToWrap_[0] = erc20AmountToWrap;

    //     return
    //         MultiTokenTransferLib.Bundle({
    //             erc1155AssetContracts: erc1155AssetContracts_,
    //             erc1155TokensToWrap: erc1155TokensToWrap_,
    //             erc1155AmountsToWrap: erc1155AmountsToWrap_,
    //             erc721AssetContracts: erc721AssetContracts_,
    //             erc721TokensToWrap: erc721TokensToWrap_,
    //             erc20AssetContracts: erc20AssetContracts_,
    //             erc20AmountsToWrap: erc20AmountsToWrap_
    //         });
    // }

    // function test_unwrap_reentrancy() public {
    //     uint256 tokenIdOfWrapped = _setup_unwrap_reentrancy();

    //     erc20Reentrancy.setToReenter(true);

    //     vm.expectRevert("ReentrancyGuard: reentrant call");

    //     vm.prank(tokenOwner);
    //     multiwrap.unwrap(tokenIdOfWrapped, 1, tokenOwner);
    // }

    // function _get_onlyWrapERC20_fuzz(uint256 _erc20AmountToWrap)
    //     internal
    //     view
    //     returns (MultiTokenTransferLib.Bundle memory onlyERC20Wrapped)
    // {
    //     address[] memory erc1155AssetContracts_;
    //     uint256[][] memory erc1155TokensToWrap_;
    //     uint256[][] memory erc1155AmountsToWrap_;

    //     address[] memory erc721AssetContracts_;
    //     uint256[][] memory erc721TokensToWrap_;

    //     address[] memory erc20AssetContracts_ = new address[](1);
    //     erc20AssetContracts_[0] = address(erc20);

    //     uint256[] memory erc20AmountsToWrap_ = new uint256[](1);
    //     erc20AmountsToWrap_[0] = _erc20AmountToWrap;

    //     return
    //         MultiTokenTransferLib.Bundle({
    //             erc1155AssetContracts: erc1155AssetContracts_,
    //             erc1155TokensToWrap: erc1155TokensToWrap_,
    //             erc1155AmountsToWrap: erc1155AmountsToWrap_,
    //             erc721AssetContracts: erc721AssetContracts_,
    //             erc721TokensToWrap: erc721TokensToWrap_,
    //             erc20AssetContracts: erc20AssetContracts_,
    //             erc20AmountsToWrap: erc20AmountsToWrap_
    //         });
    // }
}
