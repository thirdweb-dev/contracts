// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC1155.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155Test is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC1155.AirdropContent[] internal _contents;

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
            _contents.push(
                IAirdropERC1155.AirdropContent({
                    tokenAddress: address(erc1155),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: i % 5,
                    amount: 5
                })
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.startPrank(deployer);
        drop.addAirdropRecipients(_contents);
        drop.airdrop(_contents.length);
        vm.stopPrank();

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(erc1155.balanceOf(_contents[i].recipient, i % 5), 5);
        }
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 1000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 2), 2000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 3), 3000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 4), 4000);
    }

    function test_revert_airdrop_notOwner() public {
        vm.prank(address(25));
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(address(25)), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(0x00), 32)
            )
        );
        drop.addAirdropRecipients(_contents);
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), false);

        vm.startPrank(deployer);
        drop.addAirdropRecipients(_contents);
        vm.expectRevert("ERC1155: caller is not token owner nor approved");
        drop.airdrop(_contents.length);
        vm.stopPrank();
    }
}
