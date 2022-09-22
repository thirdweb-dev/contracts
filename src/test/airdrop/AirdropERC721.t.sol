// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC721.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC721Test is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC721.AirdropContent[] internal _contents;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1000);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        for (uint256 i = 0; i < 1000; i++) {
            _contents.push(
                IAirdropERC721.AirdropContent({
                    tokenAddress: address(erc721),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: i
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
            assertEq(erc721.ownerOf(i), _contents[i].recipient);
        }
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
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), false);

        vm.startPrank(deployer);
        drop.addAirdropRecipients(_contents);
        vm.expectRevert("ERC721: caller is not token owner nor approved");
        drop.airdrop(_contents.length);
        vm.stopPrank();
    }
}
