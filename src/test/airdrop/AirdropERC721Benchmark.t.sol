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

        vm.startPrank(deployer);

        drop.addAirdropRecipients(_contents);
    }

    function test_benchmark_airdrop_one_ERC721() public {
        drop.airdrop(1);
    }

    function test_benchmark_airdrop_two_ERC721() public {
        drop.airdrop(2);
    }

    function test_benchmark_airdrop_five_ERC721() public {
        drop.airdrop(5);
    }
}
