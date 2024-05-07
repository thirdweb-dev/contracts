// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { BurnToClaim, IBurnToClaim } from "contracts/extension/BurnToClaim.sol";
import "../../ExtensionUtilTest.sol";

contract MyBurnToClaim is BurnToClaim {
    function burnTokensOnOrigin(address _tokenOwner, uint256 _tokenId, uint256 _quantity) public {
        _burnTokensOnOrigin(_tokenOwner, _tokenId, _quantity);
    }

    function _canSetBurnToClaim() internal view override returns (bool) {
        return true;
    }
}

contract BurnToClaim_BurnTokensOnOrigin is ExtensionUtilTest {
    MyBurnToClaim internal ext;
    Wallet internal tokenOwner;
    uint256 internal tokenId;
    uint256 internal quantity;

    function setUp() public override {
        super.setUp();

        ext = new MyBurnToClaim();

        tokenOwner = getWallet();
        erc721.mint(address(tokenOwner), 10);
        erc1155.mint(address(tokenOwner), 1, 10);

        erc721NonBurnable.mint(address(tokenOwner), 10);
        erc1155NonBurnable.mint(address(tokenOwner), 1, 10);

        tokenOwner.setApprovalForAllERC721(address(erc721), address(ext), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(ext), true);
    }

    // ==================
    // ======= Test branch: token type is ERC721
    // ==================

    modifier whenNotBurnableERC721() {
        ext.setBurnToClaimInfo(
            IBurnToClaim.BurnToClaimInfo({
                originContractAddress: address(erc721NonBurnable),
                tokenType: IBurnToClaim.TokenType.ERC721,
                tokenId: 0,
                mintPriceForNewToken: 0,
                currency: address(erc20)
            })
        );
        _;
    }

    function test_burnTokensOnOrigin_ERC721_nonBurnable() public whenNotBurnableERC721 {
        vm.expectRevert();
        ext.burnTokensOnOrigin(address(tokenOwner), tokenId, quantity);
    }

    modifier whenBurnableERC721() {
        ext.setBurnToClaimInfo(
            IBurnToClaim.BurnToClaimInfo({
                originContractAddress: address(erc721),
                tokenType: IBurnToClaim.TokenType.ERC721,
                tokenId: 0,
                mintPriceForNewToken: 0,
                currency: address(erc20)
            })
        );
        _;
    }

    function test_burnTokensOnOrigin_ERC721() public whenBurnableERC721 {
        ext.burnTokensOnOrigin(address(tokenOwner), tokenId, quantity);

        assertEq(erc721.balanceOf(address(tokenOwner)), 9);

        vm.expectRevert();
        erc721.ownerOf(tokenId); // token doesn't exist after burning
    }

    // ==================
    // ======= Test branch: token type is ERC71155
    // ==================

    modifier whenNotBurnableERC1155() {
        ext.setBurnToClaimInfo(
            IBurnToClaim.BurnToClaimInfo({
                originContractAddress: address(erc1155NonBurnable),
                tokenType: IBurnToClaim.TokenType.ERC1155,
                tokenId: 1,
                mintPriceForNewToken: 0,
                currency: address(erc20)
            })
        );
        _;
    }

    function test_burnTokensOnOrigin_ERC1155_nonBurnable() public whenNotBurnableERC1155 {
        vm.expectRevert();
        ext.burnTokensOnOrigin(address(tokenOwner), tokenId, quantity);
    }

    modifier whenBurnableERC1155() {
        ext.setBurnToClaimInfo(
            IBurnToClaim.BurnToClaimInfo({
                originContractAddress: address(erc1155),
                tokenType: IBurnToClaim.TokenType.ERC1155,
                tokenId: 1,
                mintPriceForNewToken: 0,
                currency: address(erc20)
            })
        );
        _;
    }

    function test_burnTokensOnOrigin_ERC1155() public whenBurnableERC1155 {
        ext.burnTokensOnOrigin(address(tokenOwner), tokenId, quantity);

        assertEq(erc1155.balanceOf(address(tokenOwner), tokenId), 0);
    }
}
