// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { NFTStake } from "contracts/prebuilts/staking/NFTStake.sol";

// Test imports
import "../utils/BaseTest.sol";

contract NFTStakeBenchmarkTest is BaseTest {
    NFTStake internal stakeContract;

    address internal stakerOne;
    address internal stakerTwo;

    uint256 internal timeUnit;
    uint256 internal rewardsPerUnitTime;

    function setUp() public override {
        super.setUp();

        timeUnit = 60;
        rewardsPerUnitTime = 1;

        stakerOne = address(0x345);
        stakerTwo = address(0x567);

        erc721.mint(stakerOne, 5); // mint token id 0 to 4
        erc721.mint(stakerTwo, 5); // mint token id 5 to 9
        erc20.mint(deployer, 1000 ether); // mint reward tokens to contract admin

        stakeContract = NFTStake(payable(getContract("NFTStake")));

        // set approvals
        vm.prank(stakerOne);
        erc721.setApprovalForAll(address(stakeContract), true);

        vm.prank(stakerTwo);
        erc721.setApprovalForAll(address(stakeContract), true);

        vm.startPrank(deployer);
        erc20.approve(address(stakeContract), type(uint256).max);
        stakeContract.depositRewardTokens(100 ether);
        // erc20.transfer(address(stakeContract), 100 ether);
        vm.stopPrank();
        assertEq(stakeContract.getRewardTokenBalance(), 100 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        Benchmark: NFTStake               
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_nftStake_stake_five_tokens() public {
        vm.pauseGasMetering();

        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](5);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;
        _tokenIdsOne[3] = 3;
        _tokenIdsOne[4] = 4;

        // stake 3 tokens
        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.stake(_tokenIdsOne);
    }

    function test_benchmark_nftStake_claimRewards() public {
        vm.pauseGasMetering();
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);

        //=================== warp timestamp to claim rewards
        vm.roll(100);
        vm.warp(1000);
        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.claimRewards();
    }

    function test_benchmark_nftStake_withdraw() public {
        vm.pauseGasMetering();
        //================ first staker ======================
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        uint256[] memory _tokensToWithdraw = new uint256[](1);
        _tokensToWithdraw[0] = 1;

        vm.prank(stakerOne);
        vm.resumeGasMetering();
        stakeContract.withdraw(_tokensToWithdraw);
    }

    // function test_benchmark_nftStake_stake_one_token() public {
    //     vm.pauseGasMetering();

    //     vm.warp(1);
    //     uint256[] memory _tokenIdsOne = new uint256[](1);
    //     _tokenIdsOne[0] = 0;

    //     // stake 3 tokens
    //     vm.prank(stakerOne);
    //     vm.resumeGasMetering();
    //     stakeContract.stake(_tokenIdsOne);
    // }

    // function test_benchmark_nftStake_stake_two_tokens() public {
    //     vm.pauseGasMetering();

    //     vm.warp(1);
    //     uint256[] memory _tokenIdsOne = new uint256[](2);
    //     _tokenIdsOne[0] = 0;
    //     _tokenIdsOne[1] = 1;

    //     // stake 3 tokens
    //     vm.prank(stakerOne);
    //     vm.resumeGasMetering();
    //     stakeContract.stake(_tokenIdsOne);
    // }

    // function test_benchmark_nftStake_stake_three_tokens() public {
    //     vm.pauseGasMetering();

    //     vm.warp(1);
    //     uint256[] memory _tokenIdsOne = new uint256[](3);
    //     _tokenIdsOne[0] = 0;
    //     _tokenIdsOne[1] = 1;
    //     _tokenIdsOne[2] = 2;

    //     // stake 3 tokens
    //     vm.prank(stakerOne);
    //     vm.resumeGasMetering();
    //     stakeContract.stake(_tokenIdsOne);
    // }
}
