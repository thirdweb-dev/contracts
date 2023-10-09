// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { BurnToClaim, IBurnToClaim } from "contracts/extension/upgradeable/BurnToClaim.sol";
import "../../../ExtensionUtilTest.sol";

contract MyBurnToClaimUpg is BurnToClaim {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetBurnToClaim() internal view override returns (bool) {
        return condition;
    }
}

contract UpgradeableBurnToClaim_VerifyBurnToClaim is ExtensionUtilTest {
    MyBurnToClaimUpg internal ext;
    address internal tokenOwner;
    uint256 internal tokenId;
    uint256 internal quantity;

    function setUp() public override {
        super.setUp();

        ext = new MyBurnToClaimUpg();
        ext.setCondition(true);

        tokenOwner = getActor(1);
        erc721.mint(address(tokenOwner), 10);
        erc1155.mint(address(tokenOwner), 1, 10);
    }

    function test_verifyBurnToClaim_infoNotSet() public {
        vm.expectRevert();
        ext.verifyBurnToClaim(tokenOwner, tokenId, 1);
    }

    // ==================
    // ======= Test branch: token type is ERC721
    // ==================

    modifier whenBurnToClaimInfoSetERC721() {
        ext.setBurnToClaimInfo(
            IBurnToClaim.BurnToClaimInfo({
                originContractAddress: address(erc721),
                tokenType: IBurnToClaim.TokenType.ERC721,
                tokenId: 0,
                mintPriceForNewToken: 0,
                currency: address(erc20)
            })
        );
        IBurnToClaim.BurnToClaimInfo memory info = ext.getBurnToClaimInfo();
        _;
    }

    function test_verifyBurnToClaim_ERC721_quantity_not_1() public whenBurnToClaimInfoSetERC721 {
        quantity = 10;
        vm.expectRevert("Invalid amount");
        ext.verifyBurnToClaim(tokenOwner, tokenId, quantity);
    }

    modifier whenQuantityParamisOne() {
        quantity = 1;
        _;
    }

    function test_verifyBurnToClaim_ERC721_notOwnerOfToken()
        public
        whenBurnToClaimInfoSetERC721
        whenQuantityParamisOne
    {
        vm.expectRevert("!Owner");
        ext.verifyBurnToClaim(address(0x123), tokenId, quantity); // random address as owner
    }

    modifier whenCorrectOwner() {
        _;
    }

    function test_verifyBurnToClaim_ERC721()
        public
        whenBurnToClaimInfoSetERC721
        whenQuantityParamisOne
        whenCorrectOwner
    {
        ext.verifyBurnToClaim(tokenOwner, tokenId, quantity);
    }

    // ==================
    // ======= Test branch: token type is ERC1155
    // ==================

    modifier whenBurnToClaimInfoSetERC1155() {
        ext.setBurnToClaimInfo(
            IBurnToClaim.BurnToClaimInfo({
                originContractAddress: address(erc1155),
                tokenType: IBurnToClaim.TokenType.ERC1155,
                tokenId: 1,
                mintPriceForNewToken: 0,
                currency: address(erc20)
            })
        );
        IBurnToClaim.BurnToClaimInfo memory info = ext.getBurnToClaimInfo();
        _;
    }

    function test_verifyBurnToClaim_ERC1155_invalidTokenId() public whenBurnToClaimInfoSetERC1155 {
        vm.expectRevert("Invalid token Id");
        ext.verifyBurnToClaim(tokenOwner, tokenId, quantity); // the tokenId here is 0, but eligible one is set as 1 above
    }

    modifier whenCorrectTokenId() {
        tokenId = 1;
        _;
    }

    function test_verifyBurnToClaim_ERC1155_balanceLessThanQuantity()
        public
        whenBurnToClaimInfoSetERC1155
        whenCorrectTokenId
    {
        quantity = 100;
        vm.expectRevert("!Balance");
        ext.verifyBurnToClaim(tokenOwner, tokenId, quantity); // available balance is 10
    }

    modifier whenSufficientBalance() {
        quantity = 10;
        _;
    }

    function test_verifyBurnToClaim_ERC1155()
        public
        whenBurnToClaimInfoSetERC1155
        whenCorrectTokenId
        whenSufficientBalance
    {
        ext.verifyBurnToClaim(tokenOwner, tokenId, quantity);
    }
}
