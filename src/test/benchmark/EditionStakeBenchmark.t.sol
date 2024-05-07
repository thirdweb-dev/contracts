// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { EditionStake } from "contracts/prebuilts/staking/EditionStake.sol";

// Test imports
import "../utils/BaseTest.sol";

contract EditionStakeBenchmarkTest is BaseTest {
    EditionStake internal stakeContract;

    address internal stakerOne;
    address internal stakerTwo;

    uint256 internal defaultTimeUnit;
    uint256 internal defaultRewardsPerUnitTime;

    function setUp() public override {
        super.setUp();

        defaultTimeUnit = 60;
        defaultRewardsPerUnitTime = 1;

        stakerOne = address(0x345);
        stakerTwo = address(0x567);

        erc1155.mint(stakerOne, 0, 100); // mint 100 tokens with id 0 to stakerOne
        erc1155.mint(stakerOne, 1, 100); // mint 100 tokens with id 1 to stakerOne

        erc1155.mint(stakerTwo, 0, 100); // mint 100 tokens with id 0 to stakerTwo
        erc1155.mint(stakerTwo, 1, 100); // mint 100 tokens with id 1 to stakerTwo

        erc20.mint(deployer, 1000 ether); // mint reward tokens to contract admin

        stakeContract = EditionStake(payable(getContract("EditionStake")));

        // set approvals
        vm.prank(stakerOne);
        erc1155.setApprovalForAll(address(stakeContract), true);

        vm.prank(stakerTwo);
        erc1155.setApprovalForAll(address(stakeContract), true);

        vm.startPrank(deployer);
        erc20.approve(address(stakeContract), type(uint256).max);
        stakeContract.depositRewardTokens(100 ether);
        // erc20.transfer(address(stakeContract), 100 ether);
        vm.stopPrank();
        assertEq(stakeContract.getRewardTokenBalance(), 100 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        Benchmark: EditionStake               
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_editionStake_stake() public {
        vm.pauseGasMetering();

        vm.warp(1);
        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.stake(0, 50);
    }

    function test_benchmark_editionStake_claimRewards() public {
        vm.pauseGasMetering();
        vm.warp(1);

        // stake 50 tokens with token-id 0
        vm.prank(stakerOne);
        stakeContract.stake(0, 50);

        //=================== warp timestamp to claim rewards
        vm.roll(100);
        vm.warp(1000);

        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.claimRewards(0);
    }

    function test_benchmark_editionStake_withdraw() public {
        vm.pauseGasMetering();
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);

        vm.prank(stakerTwo);
        stakeContract.stake(1, 20);

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        // withdraw partially for stakerOne
        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.withdraw(0, 40);
    }
}
