// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC721.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC721BenchmarkTest is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC721.AirdropContent[] internal _contents;

    IAirdropERC721.AirdropContent[] internal _contents_one;

    IAirdropERC721.AirdropContent[] internal _contents_two;

    IAirdropERC721.AirdropContent[] internal _contents_five;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1000);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        for (uint256 i = 0; i < 1000; i++) {
            if (i < 1) {
                _contents_one.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
            }

            if (i < 2) {
                _contents_two.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
            }

            if (i < 5) {
                _contents_five.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
            }

            _contents.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
        }

        vm.startPrank(deployer);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdrop_one_ERC721() public {
        drop.airdrop(address(erc721), address(tokenOwner), _contents_one);
    }

    function test_benchmark_airdrop_two_ERC721() public {
        drop.airdrop(address(erc721), address(tokenOwner), _contents_two);
    }

    function test_benchmark_airdrop_five_ERC721() public {
        drop.airdrop(address(erc721), address(tokenOwner), _contents_five);
    }
}
