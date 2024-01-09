// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AirdropERC721, IAirdropERC721 } from "contracts/prebuilts/unaudited/airdrop/AirdropERC721.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC721Test is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC721.AirdropContent[] internal _contentsOne;
    IAirdropERC721.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1500);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: stateless airdrop
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdropERC721(address(erc721), address(tokenOwner), _contentsOne);

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
        }
    }

    function test_revert_airdrop_notOwner() public {
        vm.prank(address(25));
        vm.expectRevert("Not authorized.");
        drop.airdropERC721(address(erc721), address(tokenOwner), _contentsOne);
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), false);

        vm.startPrank(deployer);
        vm.expectRevert("Not owner or approved");
        drop.airdropERC721(address(erc721), address(tokenOwner), _contentsOne);
        vm.stopPrank();
    }
}

contract AirdropERC721GasTest is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1500);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        vm.startPrank(address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: gas benchmarks, etc.
    //////////////////////////////////////////////////////////////*/

    function test_safeTransferFrom_toEOA() public {
        erc721.safeTransferFrom(address(tokenOwner), address(0x123), 0);
    }

    function test_safeTransferFrom_toContract() public {
        erc721.safeTransferFrom(address(tokenOwner), address(this), 0);
    }

    function test_safeTransferFrom_toEOA_gasOverride() public {
        console.log(gasleft());
        erc721.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(0x123), 0);
        console.log(gasleft());
    }

    function test_safeTransferFrom_toContract_gasOverride() public {
        console.log(gasleft());
        erc721.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(this), 0);
        console.log(gasleft());
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
