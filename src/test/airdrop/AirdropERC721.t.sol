// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC721.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC721Test is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    uint256[] internal _tokenIds;
    address[] internal _recipients;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1000);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        for (uint256 i = 0; i < 1000; i++) {
            _tokenIds.push(i);
            _recipients.push(getActor(uint160(i)));
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdrop(address(erc721), address(tokenOwner), _recipients, _tokenIds);

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(erc721.ownerOf(i), _recipients[i]);
        }
    }

    function test_revert_airdrop_notOwner() public {
        vm.prank(address(25));
        vm.expectRevert("Not authorized");
        drop.airdrop(address(erc721), address(tokenOwner), _recipients, _tokenIds);
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), false);

        vm.prank(deployer);
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        drop.airdrop(address(erc721), address(tokenOwner), _recipients, _tokenIds);
    }

    function test_revert_airdrop_lengthMismatch() public {
        _tokenIds.push(1000);

        vm.prank(deployer);
        vm.expectRevert("length mismatch");
        drop.airdrop(address(erc721), address(tokenOwner), _recipients, _tokenIds);
    }
}
