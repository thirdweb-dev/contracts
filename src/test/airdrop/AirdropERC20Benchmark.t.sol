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

    IAirdropERC20.AirdropContent[] internal _contents_one;

    IAirdropERC20.AirdropContent[] internal _contents_two;

    IAirdropERC20.AirdropContent[] internal _contents_five;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);

        for (uint256 i = 0; i < 1000; i++) {
            if (i < 1) {
                _contents_one.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 1 ether }));
            }

            if (i < 2) {
                _contents_two.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 1 ether }));
            }

            if (i < 5) {
                _contents_five.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 1 ether }));
            }

            _contents.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 1 ether }));
        }

        vm.deal(deployer, 10_000 ether);
        vm.startPrank(deployer);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdrop_one_ERC20() public {
        drop.airdrop(address(erc20), address(tokenOwner), _contents_one);
    }

    function test_benchmark_airdrop_one_nativeToken() public {
        drop.airdrop{ value: 1 ether }(NATIVE_TOKEN, deployer, _contents_one);
    }

    function test_benchmark_airdrop_two_ERC20() public {
        drop.airdrop(address(erc20), address(tokenOwner), _contents_two);
    }

    function test_benchmark_airdrop_two_nativeToken() public {
        drop.airdrop{ value: 2 ether }(NATIVE_TOKEN, deployer, _contents_two);
    }

    function test_benchmark_airdrop_five_ERC20() public {
        drop.airdrop(address(erc20), address(tokenOwner), _contents_five);
    }

    function test_benchmark_airdrop_five_nativeToken() public {
        drop.airdrop{ value: 5 ether }(NATIVE_TOKEN, deployer, _contents_five);
    }
}
