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

        vm.startPrank(deployer);

        drop.addAirdropRecipients(_contents);
    }

    function test_benchmark_airdrop_one() public {
        drop.airdrop(1);
    }

    function test_benchmark_airdrop_two() public {
        drop.airdrop(2);
    }

    function test_benchmark_airdrop_five() public {
        drop.airdrop(5);
    }
}
