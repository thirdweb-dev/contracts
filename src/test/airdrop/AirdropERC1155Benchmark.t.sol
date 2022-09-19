// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC1155.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155BenchmarkTest is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC1155.AirdropContent[] internal _contents;

    IAirdropERC1155.AirdropContent[] internal _contents_one;

    IAirdropERC1155.AirdropContent[] internal _contents_two;

    IAirdropERC1155.AirdropContent[] internal _contents_five;

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
            if (i < 1) {
                _contents_one.push(
                    IAirdropERC1155.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i % 5, amount: 5 })
                );
            }

            if (i < 2) {
                _contents_two.push(
                    IAirdropERC1155.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i % 5, amount: 5 })
                );
            }

            if (i < 5) {
                _contents_five.push(
                    IAirdropERC1155.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i % 5, amount: 5 })
                );
            }

            _contents.push(
                IAirdropERC1155.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i % 5, amount: 5 })
            );
        }

        vm.startPrank(deployer);
    }

    function test_benchmark_airdrop_one() public {
        drop.airdrop(address(erc1155), address(tokenOwner), _contents_one);
    }

    function test_benchmark_airdrop_two() public {
        drop.airdrop(address(erc1155), address(tokenOwner), _contents_two);
    }

    function test_benchmark_airdrop_five() public {
        drop.airdrop(address(erc1155), address(tokenOwner), _contents_five);
    }
}
