// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721LazyMint } from "contracts/base/ERC721LazyMint.sol";

contract BaseERC721LazyMintTest is BaseUtilTest {
    ERC721LazyMint internal base;
    using TWStrings for uint256;

    uint256 _amount;
    string _baseURIForTokens;
    bytes _encryptedBaseURI;

    function setUp() public override {
        vm.prank(deployer);
        base = new ERC721LazyMint(NAME, SYMBOL, royaltyRecipient, royaltyBps);

        _amount = 10;
        _baseURIForTokens = "baseURI/";
        _encryptedBaseURI = "";

        vm.prank(deployer);
        base.lazyMint(_amount, _baseURIForTokens, _encryptedBaseURI);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintTo`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintTo() public {
        address recipient = address(0x123);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.startPrank(deployer);
        for (uint256 i = 0; i < _amount; i += 1) {
            base.mintTo(recipient, "");
        }

        assertEq(base.totalSupply(), currentTotalSupply + _amount);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _amount);

        for (uint256 i = 0; i < _amount; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURIForTokens, i.toString())));
            assertEq(base.ownerOf(i), recipient);
        }

        vm.stopPrank();
    }

    function test_revert_mintTo_NotAuthorized() public {
        address recipient = address(0x123);

        vm.startPrank(address(0x345));
        vm.expectRevert("Not authorized to mint.");
        base.mintTo(recipient, "");

        vm.stopPrank();
    }

    function test_revert_mintTo_NotEnoughTokens() public {
        address recipient = address(0x123);

        vm.startPrank(deployer);
        for (uint256 i = 0; i < _amount; i += 1) {
            base.mintTo(recipient, "");
        }

        vm.expectRevert("Not enough lazy minted tokens.");
        base.mintTo(recipient, "");

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `batchMintTo`
    //////////////////////////////////////////////////////////////*/

    function test_state_batchMintTo() public {
        address recipient = address(0x123);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.startPrank(deployer);
        base.batchMintTo(recipient, _amount, "", "");

        assertEq(base.totalSupply(), currentTotalSupply + _amount);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _amount);

        for (uint256 i = 0; i < _amount; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURIForTokens, i.toString())));
            assertEq(base.ownerOf(i), recipient);
        }

        vm.stopPrank();
    }

    function test_revert_batchMintTo_NotAuthorized() public {
        address recipient = address(0x123);

        vm.startPrank(address(0x345));
        vm.expectRevert("Not authorized to mint.");
        base.batchMintTo(recipient, _amount, "", "");

        vm.stopPrank();
    }

    function test_revert_batchMintTo_NotEnoughTokens() public {
        address recipient = address(0x123);

        vm.startPrank(deployer);

        vm.expectRevert("Not enough lazy minted tokens.");
        base.batchMintTo(recipient, _amount + 1, "", "");

        vm.stopPrank();
    }
}
