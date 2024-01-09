// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenStake } from "contracts/prebuilts/staking/TokenStake.sol";

// Test imports

import "../utils/BaseTest.sol";

contract TokenStakeBenchmarkTest is BaseTest {
    TokenStake internal stakeContract;

    address internal stakerOne;
    address internal stakerTwo;

    uint256 internal timeUnit;
    uint256 internal rewardRatioNumerator;
    uint256 internal rewardRatioDenominator;

    function setUp() public override {
        super.setUp();

        timeUnit = 60;
        rewardRatioNumerator = 3;
        rewardRatioDenominator = 50;

        stakerOne = address(0x345);
        stakerTwo = address(0x567);

        erc20Aux.mint(stakerOne, 1000); // mint 1000 tokens to stakerOne
        erc20Aux.mint(stakerTwo, 1000); // mint 1000 tokens to stakerTwo

        erc20.mint(deployer, 1000 ether); // mint reward tokens to contract admin

        stakeContract = TokenStake(payable(getContract("TokenStake")));

        // set approvals
        vm.prank(stakerOne);
        erc20Aux.approve(address(stakeContract), type(uint256).max);

        vm.prank(stakerTwo);
        erc20Aux.approve(address(stakeContract), type(uint256).max);

        vm.startPrank(deployer);
        erc20.approve(address(stakeContract), type(uint256).max);
        stakeContract.depositRewardTokens(100 ether);
        // erc20.transfer(address(stakeContract), 100 ether);
        vm.stopPrank();
        assertEq(stakeContract.getRewardTokenBalance(), 100 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        Benchmark: TokenStake               
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_tokenStake_stake() public {
        vm.pauseGasMetering();

        vm.warp(1);
        // stake 400 tokens
        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.stake(400);
    }

    function test_benchmark_tokenStake_claimRewards() public {
        vm.pauseGasMetering();
        vm.warp(1);

        // stake 50 tokens with token-id 0
        vm.prank(stakerOne);
        stakeContract.stake(400);

        //=================== warp timestamp to claim rewards
        vm.roll(100);
        vm.warp(1000);
        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.claimRewards();
    }

    function test_benchmark_tokenStake_withdraw() public {
        vm.pauseGasMetering();
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(400);

        vm.prank(stakerTwo);
        stakeContract.stake(200);

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        // withdraw partially for stakerOne
        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.withdraw(100);
    }
}
