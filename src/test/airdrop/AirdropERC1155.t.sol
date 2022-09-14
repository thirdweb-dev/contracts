// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC1155.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155Test is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    address[] internal _recipients;
    uint256[] internal _amounts;
    uint256[] internal _tokenIds;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC1155(getContract("AirdropERC1155"));

        tokenOwner = getWallet();

        erc1155.mint(address(tokenOwner), 0, 1000);
        erc1155.mint(address(tokenOwner), 1, 2000);
        erc1155.mint(address(tokenOwner), 2, 3000);
        erc1155.mint(address(tokenOwner), 3, 4000);
        erc1155.mint(address(tokenOwner), 4, 5000);

        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), true);

        for (uint256 i = 0; i < 1000; i++) {
            _recipients.push(getActor(uint160(i)));
            _tokenIds.push(i % 5);
            _amounts.push(5);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdrop(address(erc1155), address(tokenOwner), _recipients, _amounts, _tokenIds);

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(erc1155.balanceOf(_recipients[i], i % 5), 5);
        }
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 1000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 2), 2000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 3), 3000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 4), 4000);
    }

    function test_revert_airdrop_notOwner() public {
        vm.prank(address(25));
        vm.expectRevert("Not authorized");
        drop.airdrop(address(erc1155), address(tokenOwner), _recipients, _amounts, _tokenIds);
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), false);

        vm.prank(deployer);
        vm.expectRevert("ERC1155: caller is not owner nor approved");
        drop.airdrop(address(erc1155), address(tokenOwner), _recipients, _amounts, _tokenIds);
    }

    function test_revert_airdrop_lengthMismatch() public {
        _tokenIds.push(6);

        vm.prank(deployer);
        vm.expectRevert("length mismatch");
        drop.airdrop(address(erc1155), address(tokenOwner), _recipients, _amounts, _tokenIds);
    }
}
