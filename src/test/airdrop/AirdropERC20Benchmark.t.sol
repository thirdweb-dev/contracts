// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC20.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC20BenchmarkTest is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    uint256[] internal _amounts;
    address[] internal _recipients;

    uint256[] internal _amounts_one;
    address[] internal _recipients_one;

    uint256[] internal _amounts_two;
    address[] internal _recipients_two;

    uint256[] internal _amounts_five;
    address[] internal _recipients_five;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);

        for (uint256 i = 0; i < 1000; i++) {
            if (i < 1) {
                _amounts_one.push(1 ether);
                _recipients_one.push(getActor(uint160(i)));
            }

            if (i < 2) {
                _amounts_two.push(1 ether);
                _recipients_two.push(getActor(uint160(i)));
            }

            if (i < 5) {
                _amounts_five.push(1 ether);
                _recipients_five.push(getActor(uint160(i)));
            }

            _amounts.push(1 ether);
            _recipients.push(getActor(uint160(i)));
        }

        vm.deal(deployer, 10_000 ether);
        vm.startPrank(deployer);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdrop_one_ERC20() public {
        drop.airdrop(address(erc20), address(tokenOwner), _recipients_one, _amounts_one);
    }

    function test_benchmark_airdrop_one_nativeToken() public {
        drop.airdrop{ value: 1 ether }(NATIVE_TOKEN, deployer, _recipients_one, _amounts_one);
    }

    function test_benchmark_airdrop_two_ERC20() public {
        drop.airdrop(address(erc20), address(tokenOwner), _recipients_two, _amounts_two);
    }

    function test_benchmark_airdrop_two_nativeToken() public {
        drop.airdrop{ value: 2 ether }(NATIVE_TOKEN, deployer, _recipients_two, _amounts_two);
    }

    function test_benchmark_airdrop_five_ERC20() public {
        drop.airdrop(address(erc20), address(tokenOwner), _recipients_five, _amounts_five);
    }

    function test_benchmark_airdrop_five_nativeToken() public {
        drop.airdrop{ value: 5 ether }(NATIVE_TOKEN, deployer, _recipients_five, _amounts_five);
    }
}
