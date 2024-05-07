// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721LazyMint } from "contracts/base/ERC721LazyMint.sol";

contract BaseERC721LazyMintTest is BaseUtilTest {
    ERC721LazyMint internal base;
    using Strings for uint256;

    uint256 _amount;
    string _baseURIForTokens;
    bytes _encryptedBaseURI;

    function setUp() public override {
        vm.prank(deployer);
        base = new ERC721LazyMint(deployer, NAME, SYMBOL, royaltyRecipient, royaltyBps);

        _amount = 10;
        _baseURIForTokens = "baseURI/";
        _encryptedBaseURI = "";

        vm.prank(deployer);
        base.lazyMint(_amount, _baseURIForTokens, _encryptedBaseURI);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `claim`
    //////////////////////////////////////////////////////////////*/

    function test_state_claim() public {
        address recipient = address(0x123);
        uint256 quantity = 5;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.startPrank(recipient);

        base.claim(recipient, quantity);

        assertEq(base.totalSupply(), currentTotalSupply + quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + quantity);

        for (uint256 i = 0; i < quantity; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURIForTokens, i.toString())));
            assertEq(base.ownerOf(i), recipient);
        }

        vm.stopPrank();
    }

    function test_revert_claim_NotEnoughTokens() public {
        address recipient = address(0x123);

        vm.startPrank(recipient);

        vm.expectRevert("Not enough lazy minted tokens.");
        base.claim(recipient, _amount + 1);

        vm.stopPrank();
    }
}
