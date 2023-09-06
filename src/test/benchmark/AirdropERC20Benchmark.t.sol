// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AirdropERC20, IAirdropERC20 } from "contracts/prebuilts/unaudited/airdrop/AirdropERC20.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

import "../mocks/MockERC20NonCompliant.sol";

contract AirdropERC20BenchmarkTest is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC20.AirdropContent[] internal _contentsOne;
    IAirdropERC20.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 10 ether }));
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 10 ether }));
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Benchmark: AirdropERC20
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropERC20_airdrop() public {
        vm.pauseGasMetering();
        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.airdropERC20(address(erc20), address(tokenOwner), _contentsOne);
    }
}
