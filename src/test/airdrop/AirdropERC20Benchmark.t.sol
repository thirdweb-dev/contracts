// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC20.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC20BenchmarkTest is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC20.AirdropContent[] internal _contents;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);

        for (uint256 i = 0; i < 1000; i++) {
            _contents.push(
                IAirdropERC20.AirdropContent({
                    tokenAddress: address(erc20),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    amount: 1 ether
                })
            );
        }

        vm.deal(deployer, 10_000 ether);
        vm.startPrank(deployer);

        drop.addAirdropRecipients(_contents);
    }

    function test_benchmark_airdrop_one_ERC20() public {
        drop.airdrop(1);
    }

    function test_benchmark_airdrop_two_ERC20() public {
        drop.airdrop(2);
    }

    function test_benchmark_airdrop_five_ERC20() public {
        drop.airdrop(5);
    }
}
