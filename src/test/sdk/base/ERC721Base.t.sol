// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721Base } from "contracts/base/ERC721Base.sol";

contract BaseERC721BaseTest is BaseUtilTest {
    ERC721Base internal base;
    using Strings for uint256;

    function setUp() public override {
        vm.prank(deployer);
        base = new ERC721Base(deployer, NAME, SYMBOL, royaltyRecipient, royaltyBps);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintTo`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintTo() public {
        address recipient = address(0x123);
        string memory _tokenURI = "tokenURI";

        uint256 nextTokenId = base.nextTokenIdToMint();
        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.prank(deployer);
        base.mintTo(recipient, _tokenURI);

        assertEq(base.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(base.tokenURI(nextTokenId), _tokenURI);
        assertEq(base.totalSupply(), currentTotalSupply + 1);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + 1);
        assertEq(base.ownerOf(nextTokenId), recipient);
    }

    function test_revert_mintTo_NotAuthorized() public {
        address recipient = address(0x123);
        string memory _tokenURI = "tokenURI";

        vm.expectRevert("Not authorized to mint.");
        vm.prank(address(0x1));
        base.mintTo(recipient, _tokenURI);
    }

    function test_revert_mintTo_MintToZeroAddress() public {
        string memory _tokenURI = "tokenURI";

        vm.expectRevert(bytes4(abi.encodeWithSignature("MintToZeroAddress()")));
        vm.prank(deployer);
        base.mintTo(address(0), _tokenURI);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `batchMintTo`
    //////////////////////////////////////////////////////////////*/

    function test_state_batchMintTo() public {
        address recipient = address(0x123);
        uint256 _quantity = 100;
        string memory _baseURI = "baseURI/";

        uint256 nextTokenId = base.nextTokenIdToMint();
        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.prank(deployer);
        base.batchMintTo(recipient, _quantity, _baseURI, "");

        assertEq(base.nextTokenIdToMint(), nextTokenId + _quantity);
        assertEq(base.totalSupply(), currentTotalSupply + _quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _quantity);
        for (uint256 i = nextTokenId; i < _quantity; i += 1) {
            assertEq(base.tokenURI(i), string(abi.encodePacked(_baseURI, i.toString())));
            assertEq(base.ownerOf(i), recipient);
        }
    }

    function test_revert_batchMintTo_NotAuthorized() public {
        address recipient = address(0x123);
        uint256 _quantity = 100;
        string memory _baseURI = "baseURI/";

        vm.expectRevert("Not authorized to mint.");
        vm.prank(address(0x1));
        base.batchMintTo(recipient, _quantity, _baseURI, "");
    }

    function test_revert_batchMintTo_MintToZeroAddress() public {
        uint256 _quantity = 100;
        string memory _baseURI = "baseURI/";

        vm.expectRevert(bytes4(abi.encodeWithSignature("MintToZeroAddress()")));
        vm.prank(deployer);
        base.batchMintTo(address(0), _quantity, _baseURI, "");
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `burn`
    //////////////////////////////////////////////////////////////*/

    function test_state_burn_Owner() public {
        address recipient = address(0x123);
        string memory _tokenURI = "tokenURI";

        uint256 nextTokenId = base.nextTokenIdToMint();
        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.prank(deployer);
        base.mintTo(recipient, _tokenURI);

        vm.prank(recipient);
        base.burn(nextTokenId);
        assertEq(base.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(base.tokenURI(nextTokenId), _tokenURI);
        assertEq(base.totalSupply(), currentTotalSupply);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient);

        vm.expectRevert(bytes4(abi.encodeWithSignature("OwnerQueryForNonexistentToken()")));
        assertEq(base.ownerOf(nextTokenId), address(0));
    }

    function test_state_burn_Approved() public {
        address recipient = address(0x123);
        string memory _tokenURI = "tokenURI";

        address operator = address(0x789);

        uint256 nextTokenId = base.nextTokenIdToMint();
        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.prank(deployer);
        base.mintTo(recipient, _tokenURI);

        vm.prank(recipient);
        base.setApprovalForAll(operator, true);

        vm.prank(operator);
        base.burn(nextTokenId);
        assertEq(base.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(base.tokenURI(nextTokenId), _tokenURI);
        assertEq(base.totalSupply(), currentTotalSupply);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient);

        vm.expectRevert(bytes4(abi.encodeWithSignature("OwnerQueryForNonexistentToken()")));
        assertEq(base.ownerOf(nextTokenId), address(0));
    }

    function test_revert_burn_NotOwnerNorApproved() public {
        address recipient = address(0x123);
        string memory _tokenURI = "tokenURI";

        uint256 nextTokenId = base.nextTokenIdToMint();

        vm.prank(deployer);
        base.mintTo(recipient, _tokenURI);

        vm.prank(address(0x789));
        vm.expectRevert(bytes4(abi.encodeWithSignature("TransferCallerNotOwnerNorApproved()")));
        base.burn(nextTokenId);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `isApprovedOrOwner`
    //////////////////////////////////////////////////////////////*/

    function test_isApprovedOrOwner() public {
        address recipient = address(0x123);
        string memory _tokenURI = "tokenURI";

        address operator = address(0x789);

        uint256 nextTokenId = base.nextTokenIdToMint();

        vm.prank(deployer);
        base.mintTo(recipient, _tokenURI);

        assertFalse(base.isApprovedOrOwner(operator, nextTokenId));
        assertEq(base.isApprovedOrOwner(recipient, nextTokenId), true);

        vm.prank(recipient);
        base.approve(operator, nextTokenId);

        assertEq(base.isApprovedOrOwner(operator, nextTokenId), true);
    }
}
