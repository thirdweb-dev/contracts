// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenStake } from "contracts/staking/TokenStake.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../utils/BaseTest.sol";

contract TokenStakeTest is BaseTest {
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

        stakeContract = TokenStake(getContract("TokenStake"));

        // set approvals
        vm.prank(stakerOne);
        erc20Aux.approve(address(stakeContract), type(uint256).max);

        vm.prank(stakerTwo);
        erc20Aux.approve(address(stakeContract), type(uint256).max);

        vm.prank(deployer);
        erc20.transfer(address(stakeContract), 100 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Stake
    //////////////////////////////////////////////////////////////*/

    function test_state_stake() public {
        //================ first staker ======================
        vm.warp(1);

        // stake 400 tokens
        vm.prank(stakerOne);
        stakeContract.stake(400);
        uint256 timeOfLastUpdate_one = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc20Aux.balanceOf(address(stakeContract)), 400);
        assertEq(erc20Aux.balanceOf(address(stakerOne)), 600);

        // check available rewards right after staking
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(_amountStaked, 400);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(100);
        vm.warp(1000);

        // check available rewards after warp
        (, _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate_one) * 400) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        //================ second staker ======================
        vm.roll(200);
        vm.warp(2000);

        // stake 20 tokens with token-id 0
        vm.prank(stakerTwo);
        stakeContract.stake(200);
        uint256 timeOfLastUpdate_two = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc20Aux.balanceOf(address(stakeContract)), 200 + 400); // sum of staked tokens by both stakers
        assertEq(erc20Aux.balanceOf(address(stakerTwo)), 800);

        // check available rewards right after staking
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);

        assertEq(_amountStaked, 200);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(300);
        vm.warp(3000);

        // check available rewards for stakerOne
        (, _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate_one) * 400) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        // check available rewards for stakerTwo
        (, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);

        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate_two) * 200) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );
    }

    function test_revert_stake_stakingZeroTokens() public {
        // stake 0 tokens

        vm.prank(stakerOne);
        vm.expectRevert("Staking 0 tokens");
        stakeContract.stake(0);
    }

    /*///////////////////////////////////////////////////////////////
                    Unit tests: claimRewards
    //////////////////////////////////////////////////////////////*/

    function test_state_claimRewards() public {
        //================ setup stakerOne ======================
        vm.warp(1);

        // stake 50 tokens with token-id 0
        vm.prank(stakerOne);
        stakeContract.stake(400);
        uint256 timeOfLastUpdate_one = block.timestamp;

        //=================== warp timestamp to claim rewards
        vm.roll(100);
        vm.warp(1000);

        vm.prank(stakerOne);
        stakeContract.claimRewards();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerOne),
            (((((block.timestamp - timeOfLastUpdate_one) * 400) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        // check available rewards after claiming
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(_amountStaked, 400);
        assertEq(_availableRewards, 0);

        //================ setup stakerTwo ======================

        // stake 20 tokens with token-id 1
        vm.prank(stakerTwo);
        stakeContract.stake(200);
        uint256 timeOfLastUpdate_two = block.timestamp;

        //=================== warp timestamp to claim rewards
        vm.roll(200);
        vm.warp(2000);

        vm.prank(stakerTwo);
        stakeContract.claimRewards();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerTwo),
            (((((block.timestamp - timeOfLastUpdate_two) * 200) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        // check available rewards after claiming -- stakerTwo
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);
        assertEq(_amountStaked, 200);
        assertEq(_availableRewards, 0);

        // check available rewards -- stakerOne
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfo(stakerOne);
        assertEq(_amountStaked, 400);
        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate_two) * 400) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );
    }

    function test_revert_claimRewards_noRewards() public {
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(400);

        //=================== try to claim rewards in same block

        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        stakeContract.claimRewards();

        //======= withdraw tokens and claim rewards
        vm.roll(100);
        vm.warp(1000);

        vm.prank(stakerOne);
        stakeContract.withdraw(400);
        vm.prank(stakerOne);
        stakeContract.claimRewards();

        //===== try to claim rewards again
        vm.roll(200);
        vm.warp(2000);
        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        stakeContract.claimRewards();
    }

    /*///////////////////////////////////////////////////////////////
                    Unit tests: stake conditions
    //////////////////////////////////////////////////////////////*/

    function test_state_setRewardRatio() public {
        // set value and check
        vm.prank(deployer);
        stakeContract.setRewardRatio(3, 70);
        assertEq(3, stakeContract.rewardRatioNumerator());
        assertEq(70, stakeContract.rewardRatioDenominator());

        //================ stake tokens
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(400);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setRewardRatio(3, 80);
        assertEq(3, stakeContract.rewardRatioNumerator());
        assertEq(80, stakeContract.rewardRatioDenominator());
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for rewardsPerUnitTime for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(_availableRewards, (((((block.timestamp - timeOfLastUpdate) * 400) * 3) / timeUnit) / 70));

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _newRewards,
            _availableRewards + (((((block.timestamp - newTimeOfLastUpdate) * 400) * 3) / timeUnit) / 80)
        );
    }

    function test_state_setTimeUnit() public {
        // set value and check
        uint256 timeUnit = 100;
        vm.prank(deployer);
        stakeContract.setTimeUnit(timeUnit);
        assertEq(timeUnit, stakeContract.timeUnit());

        //================ stake tokens
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(400);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set timeUnit
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setTimeUnit(200);
        assertEq(200, stakeContract.timeUnit());
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for timeUnit for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate) * 400) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _newRewards,
            _availableRewards +
                (((((block.timestamp - newTimeOfLastUpdate) * 400) * rewardRatioNumerator) / 200) /
                    rewardRatioDenominator)
        );
    }

    function test_revert_setRewardRatio_notAuthorized() public {
        vm.expectRevert("Not authorized");
        stakeContract.setRewardRatio(1, 2);
    }

    function test_revert_setRewardRatio_divideByZero() public {
        vm.prank(deployer);
        vm.expectRevert("divide by 0");
        stakeContract.setRewardRatio(1, 0);
    }

    function test_revert_setTimeUnit_notAuthorized() public {
        vm.expectRevert("Not authorized");
        stakeContract.setTimeUnit(1);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: withdraw
    //////////////////////////////////////////////////////////////*/

    function test_state_withdraw() public {
        //================ stake different tokens ======================
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(400);

        vm.prank(stakerTwo);
        stakeContract.stake(200);

        uint256 timeOfLastUpdate = block.timestamp;

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        // withdraw partially for stakerOne
        vm.prank(stakerOne);
        stakeContract.withdraw(100);
        uint256 timeOfLastUpdateLatest = block.timestamp;

        // check balances/ownership after withdraw
        assertEq(erc20Aux.balanceOf(stakerOne), 700);
        assertEq(erc20Aux.balanceOf(stakerTwo), 800);
        assertEq(erc20Aux.balanceOf(address(stakeContract)), (400 - 100) + 200);

        // check available rewards after withdraw
        (, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);
        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate) * 400) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        (, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);
        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate) * 200) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        // check available rewards some time after withdraw
        vm.roll(200);
        vm.warp(2000);

        // check rewards for stakerOne
        (, _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((((timeOfLastUpdateLatest - timeOfLastUpdate) * 400)) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator) +
                ((((((block.timestamp - timeOfLastUpdateLatest) * 300)) * rewardRatioNumerator) / timeUnit) /
                    rewardRatioDenominator)
        );

        // withdraw partially for stakerTwo
        vm.prank(stakerTwo);
        stakeContract.withdraw(100);
        timeOfLastUpdateLatest = block.timestamp;

        // check balances/ownership after withdraw
        assertEq(erc20Aux.balanceOf(stakerOne), 700);
        assertEq(erc20Aux.balanceOf(stakerTwo), 900);
        assertEq(erc20Aux.balanceOf(address(stakeContract)), (400 - 100) + (200 - 100));

        // check rewards for stakerTwo
        (, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);

        assertEq(
            _availableRewards,
            ((((((block.timestamp - timeOfLastUpdate) * 200)) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );

        // check rewards for stakerTwo after some time
        vm.roll(300);
        vm.warp(3000);
        (, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);

        assertEq(
            _availableRewards,
            ((((((timeOfLastUpdateLatest - timeOfLastUpdate) * 200)) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator) +
                ((((((block.timestamp - timeOfLastUpdateLatest) * 100)) * rewardRatioNumerator) / timeUnit) /
                    rewardRatioDenominator)
        );
    }

    function test_revert_withdraw_withdrawingZeroTokens() public {
        vm.expectRevert("Withdrawing 0 tokens");
        stakeContract.withdraw(0);
    }

    function test_revert_withdraw_withdrawingMoreThanStaked() public {
        // stake tokens
        vm.prank(stakerOne);
        stakeContract.stake(400);

        vm.prank(stakerTwo);
        stakeContract.stake(200);

        // trying to withdraw more than staked
        vm.roll(200);
        vm.warp(2000);

        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(500);

        // withdraw partially
        vm.prank(stakerOne);
        stakeContract.withdraw(300);

        // trying to withdraw more than staked
        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(500);

        // re-stake
        vm.prank(stakerOne);
        stakeContract.stake(300);

        // trying to withdraw more than staked
        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(500);
    }
}
