// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { EditionStake } from "contracts/prebuilts/staking/EditionStake.sol";

// Test imports

import "../utils/BaseTest.sol";

contract EditionStakeTest is BaseTest {
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
            Unit tests: Stake
            - with default time-unit and rewards
            - different token-ids staked by stakers
    //////////////////////////////////////////////////////////////*/

    function test_state_stake_defaults_differentTokens() public {
        //================ first staker ======================
        vm.warp(1);

        // stake 50 tokens with token-id 0
        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate_one = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc1155.balanceOf(address(stakeContract), 0), 50);
        assertEq(erc1155.balanceOf(address(stakerOne), 0), 50);

        // check available rewards right after staking
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(_amountStaked, 50);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(100);
        vm.warp(1000);

        // check available rewards after warp
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        //================ second staker ======================
        vm.roll(200);
        vm.warp(2000);

        // stake 20 tokens with token-id 1
        vm.prank(stakerTwo);
        stakeContract.stake(1, 20);
        uint256 timeOfLastUpdate_two = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc1155.balanceOf(address(stakeContract), 1), 20);
        assertEq(erc1155.balanceOf(address(stakerTwo), 1), 80);

        // check available rewards right after staking
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerTwo);

        assertEq(_amountStaked, 20);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(300);
        vm.warp(3000);

        // check available rewards for stakerOne
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards for stakerTwo
        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerTwo);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_two) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    function test_revert_stake_stakingZeroTokens() public {
        // stake 0 tokens

        vm.prank(stakerOne);
        vm.expectRevert("Staking 0 tokens");
        stakeContract.stake(0, 0);
    }

    function test_revert_stake_notBalanceOrApproved() public {
        // stake unowned tokens
        vm.prank(stakerOne);
        vm.expectRevert("ERC1155: insufficient balance for transfer");
        stakeContract.stake(2, 10);
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: Stake
            - with default time-unit and rewards
            - same token-id staked by stakers
    //////////////////////////////////////////////////////////////*/

    function test_state_stake_defaults_sameToken() public {
        //================ first staker ======================
        vm.warp(1);

        // stake 50 tokens with token-id 0
        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate_one = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc1155.balanceOf(address(stakeContract), 0), 50);
        assertEq(erc1155.balanceOf(address(stakerOne), 0), 50);

        // check available rewards right after staking
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(_amountStaked, 50);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(100);
        vm.warp(1000);

        // check available rewards after warp
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        //================ second staker ======================
        vm.roll(200);
        vm.warp(2000);

        // stake 20 tokens with token-id 0
        vm.prank(stakerTwo);
        stakeContract.stake(0, 20);
        uint256 timeOfLastUpdate_two = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc1155.balanceOf(address(stakeContract), 0), 20 + 50); // sum of staked tokens by both stakers
        assertEq(erc1155.balanceOf(address(stakerTwo), 0), 80);

        // check available rewards right after staking
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerTwo);

        assertEq(_amountStaked, 20);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(300);
        vm.warp(3000);

        // check available rewards for stakerOne
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards for stakerTwo
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerTwo);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_two) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: claimRewards
            - default timeUnit and rewards
            - different token-ids staked by stakers
    //////////////////////////////////////////////////////////////*/

    function test_state_claimRewards_defaults_differentTokens() public {
        //================ setup stakerOne ======================
        vm.warp(1);

        // stake 50 tokens with token-id 0
        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate_one = block.timestamp;

        //=================== warp timestamp to claim rewards
        vm.roll(100);
        vm.warp(1000);

        uint256 rewardBalanceBefore = stakeContract.getRewardTokenBalance();
        vm.prank(stakerOne);
        stakeContract.claimRewards(0);
        uint256 rewardBalanceAfter = stakeContract.getRewardTokenBalance();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerOne),
            ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
        assertEq(
            rewardBalanceAfter,
            rewardBalanceBefore -
                ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards after claiming
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(_amountStaked, 50);
        assertEq(_availableRewards, 0);

        //================ setup stakerTwo ======================

        // stake 20 tokens with token-id 1
        vm.prank(stakerTwo);
        stakeContract.stake(1, 20);
        uint256 timeOfLastUpdate_two = block.timestamp;

        //=================== warp timestamp to claim rewards
        vm.roll(200);
        vm.warp(2000);

        rewardBalanceBefore = stakeContract.getRewardTokenBalance();
        vm.prank(stakerTwo);
        stakeContract.claimRewards(1);
        rewardBalanceAfter = stakeContract.getRewardTokenBalance();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerTwo),
            ((((block.timestamp - timeOfLastUpdate_two) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
        assertEq(
            rewardBalanceAfter,
            rewardBalanceBefore -
                ((((block.timestamp - timeOfLastUpdate_two) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards after claiming -- stakerTwo
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerTwo);
        assertEq(_amountStaked, 20);
        assertEq(_availableRewards, 0);

        // check available rewards -- stakerOne
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);
        assertEq(_amountStaked, 50);
        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_two) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    function test_revert_claimRewards_noRewards() public {
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);

        //=================== try to claim rewards for a different token

        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        stakeContract.claimRewards(1);

        //=================== try to claim rewards in same block

        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        stakeContract.claimRewards(0);

        //======= withdraw tokens and claim rewards
        vm.roll(100);
        vm.warp(1000);

        vm.prank(stakerOne);
        stakeContract.withdraw(0, 50);
        vm.prank(stakerOne);
        stakeContract.claimRewards(0);

        //===== try to claim rewards again
        vm.roll(200);
        vm.warp(2000);
        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        stakeContract.claimRewards(0);
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: claimRewards
            - default timeUnit and rewards
            - same token-ids staked by stakers
    //////////////////////////////////////////////////////////////*/

    function test_state_claimRewards_defaults_sameToken() public {
        //================ setup stakerOne ======================
        vm.warp(1);

        // stake 50 tokens with token-id 0
        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate_one = block.timestamp;

        //=================== warp timestamp to claim rewards
        vm.roll(100);
        vm.warp(1000);

        uint256 rewardBalanceBefore = stakeContract.getRewardTokenBalance();
        vm.prank(stakerOne);
        stakeContract.claimRewards(0);
        uint256 rewardBalanceAfter = stakeContract.getRewardTokenBalance();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerOne),
            ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
        assertEq(
            rewardBalanceAfter,
            rewardBalanceBefore -
                ((((block.timestamp - timeOfLastUpdate_one) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards after claiming
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(_amountStaked, 50);
        assertEq(_availableRewards, 0);

        //================ setup stakerTwo ======================

        // stake 20 tokens with token-id 1
        vm.prank(stakerTwo);
        stakeContract.stake(0, 20);
        uint256 timeOfLastUpdate_two = block.timestamp;

        //=================== warp timestamp to claim rewards
        vm.roll(200);
        vm.warp(2000);

        rewardBalanceBefore = stakeContract.getRewardTokenBalance();
        vm.prank(stakerTwo);
        stakeContract.claimRewards(0);
        rewardBalanceAfter = stakeContract.getRewardTokenBalance();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerTwo),
            ((((block.timestamp - timeOfLastUpdate_two) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
        assertEq(
            rewardBalanceAfter,
            rewardBalanceBefore -
                ((((block.timestamp - timeOfLastUpdate_two) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards after claiming -- stakerTwo
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerTwo);
        assertEq(_amountStaked, 20);
        assertEq(_availableRewards, 0);

        // check available rewards -- stakerOne
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);
        assertEq(_amountStaked, 50);
        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_two) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: stake conditions
            - set rewards for token0
            - default time unit
    //////////////////////////////////////////////////////////////*/

    function test_state_setRewardsPerUnitTime_token0() public {
        // set value and check
        uint256 rewardsPerUnitTime = 50;
        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(0, rewardsPerUnitTime);
        assertEq(rewardsPerUnitTime, stakeContract.getRewardsPerUnitTime(0));

        //================ stake tokens
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(0, 200);
        assertEq(200, stakeContract.getRewardsPerUnitTime(0));
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for rewardsPerUnitTime for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 50) * rewardsPerUnitTime) / defaultTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * 50) * 200) / defaultTimeUnit)
        );

        // =========== token 1
        //================ stake tokens

        vm.prank(stakerOne);
        stakeContract.stake(1, 20);
        timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime for token-0
        vm.roll(400);
        vm.warp(4000);

        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(0, 300);
        assertEq(300, stakeContract.getRewardsPerUnitTime(0));
        newTimeOfLastUpdate = block.timestamp;

        // check available rewards for token-1 -- should use defaultRewardsPerUnitTime for calculation
        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(500);
        vm.warp(5000);

        (, _newRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        assertEq(
            _newRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: stake conditions
            - set rewards for both tokens
            - default time unit
    //////////////////////////////////////////////////////////////*/

    function test_state_setRewardsPerUnitTime_bothTokens() public {
        // set value and check
        uint256 rewardsPerUnitTime = 50;
        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(0, rewardsPerUnitTime);
        assertEq(rewardsPerUnitTime, stakeContract.getRewardsPerUnitTime(0));

        //================ stake tokens
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(0, 200);
        assertEq(200, stakeContract.getRewardsPerUnitTime(0));
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for rewardsPerUnitTime for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 50) * rewardsPerUnitTime) / defaultTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * 50) * 200) / defaultTimeUnit)
        );

        // =========== token 1
        //================ stake tokens

        vm.prank(stakerOne);
        stakeContract.stake(1, 20);
        timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and set rewardsPerUnitTime for token-1
        vm.roll(400);
        vm.warp(4000);

        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(1, 300);
        assertEq(300, stakeContract.getRewardsPerUnitTime(1));
        newTimeOfLastUpdate = block.timestamp;

        // check available rewards for token-1 -- should use defaultRewardsPerUnitTime for calculation
        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(500);
        vm.warp(5000);

        (, _newRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        // should calculate based on newTimeOfLastUpdate and rewardsPerUnitTime (not default)
        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * 20) * 300) / defaultTimeUnit)
        );
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: stake conditions
            - default rewards
            - set time unit for token0
    //////////////////////////////////////////////////////////////*/

    function test_state_setTimeUnit_token0() public {
        // set value and check
        uint80 timeUnit = 100;
        vm.prank(deployer);
        stakeContract.setTimeUnit(0, timeUnit);
        assertEq(timeUnit, stakeContract.getTimeUnit(0));

        //================ stake tokens
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set timeUnit
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setTimeUnit(0, 200);
        assertEq(200, stakeContract.getTimeUnit(0));
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for timeUnit for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 50) * defaultRewardsPerUnitTime) / timeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * 50) * defaultRewardsPerUnitTime) / 200)
        );

        // =========== token 1
        //================ stake tokens

        vm.prank(stakerOne);
        stakeContract.stake(1, 20);
        timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime for token-0
        vm.roll(400);
        vm.warp(4000);

        vm.prank(deployer);
        stakeContract.setTimeUnit(0, 10);
        assertEq(10, stakeContract.getTimeUnit(0));
        newTimeOfLastUpdate = block.timestamp;

        // check available rewards for token-1 -- should use defaultTimeUnit for calculation
        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(500);
        vm.warp(5000);

        (, _newRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        assertEq(
            _newRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: stake conditions
            - default rewards
            - set time unit for both tokens
    //////////////////////////////////////////////////////////////*/

    function test_state_setTimeUnit_bothTokens() public {
        // set value and check
        uint80 timeUnit = 100;
        vm.prank(deployer);
        stakeContract.setTimeUnit(0, timeUnit);
        assertEq(timeUnit, stakeContract.getTimeUnit(0));

        //================ stake tokens
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setTimeUnit(0, 200);
        assertEq(200, stakeContract.getTimeUnit(0));
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for timeUnit for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 50) * defaultRewardsPerUnitTime) / timeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * 50) * defaultRewardsPerUnitTime) / 200)
        );

        // =========== token 1
        //================ stake tokens

        vm.prank(stakerOne);
        stakeContract.stake(1, 20);
        timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and set timeUnit for token-1
        vm.roll(400);
        vm.warp(4000);

        vm.prank(deployer);
        stakeContract.setTimeUnit(1, 300);
        assertEq(300, stakeContract.getTimeUnit(1));
        newTimeOfLastUpdate = block.timestamp;

        // check available rewards for token-1 -- should use defaultTimeUnit for calculation
        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(500);
        vm.warp(5000);

        (, _newRewards) = stakeContract.getStakeInfoForToken(1, stakerOne);

        // should calculate based on newTimeOfLastUpdate and new time unit (not default)
        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / 300)
        );
    }

    function test_revert_setRewardsPerUnitTime_notAuthorized() public {
        vm.expectRevert("Not authorized");
        stakeContract.setRewardsPerUnitTime(0, 1);
    }

    function test_revert_setTimeUnit_notAuthorized() public {
        vm.expectRevert("Not authorized");
        stakeContract.setTimeUnit(0, 1);
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: withdraw
            - different token-ids staked by stakers
    //////////////////////////////////////////////////////////////*/

    function test_state_withdraw_differentTokens() public {
        //================ stake different tokens ======================
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);

        vm.prank(stakerTwo);
        stakeContract.stake(1, 20);

        uint256 timeOfLastUpdate = block.timestamp;

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        // withdraw partially for stakerOne
        vm.prank(stakerOne);
        stakeContract.withdraw(0, 40);
        uint256 timeOfLastUpdateLatest = block.timestamp;

        // check balances/ownership after withdraw
        assertEq(erc1155.balanceOf(stakerOne, 0), 90);
        assertEq(erc1155.balanceOf(address(stakeContract), 0), 10);
        assertEq(erc1155.balanceOf(stakerTwo, 1), 80);
        assertEq(erc1155.balanceOf(address(stakeContract), 1), 20);

        // check available rewards after withdraw
        (, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);
        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerTwo);
        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards some time after withdraw
        vm.roll(200);
        vm.warp(2000);

        // check rewards for stakerOne
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            (((((timeOfLastUpdateLatest - timeOfLastUpdate) * 50)) * defaultRewardsPerUnitTime) / defaultTimeUnit) +
                (((((block.timestamp - timeOfLastUpdateLatest) * 10)) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // withdraw partially for stakerTwo
        vm.prank(stakerTwo);
        stakeContract.withdraw(1, 10);
        timeOfLastUpdateLatest = block.timestamp;

        // check balances/ownership after withdraw
        assertEq(erc1155.balanceOf(stakerOne, 0), 90);
        assertEq(erc1155.balanceOf(address(stakeContract), 0), 10);
        assertEq(erc1155.balanceOf(stakerTwo, 1), 90);
        assertEq(erc1155.balanceOf(address(stakeContract), 1), 10);

        // check rewards for stakerTwo
        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerTwo);

        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate) * 20)) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check rewards for stakerTwo after some time
        vm.roll(300);
        vm.warp(3000);
        (, _availableRewards) = stakeContract.getStakeInfoForToken(1, stakerTwo);

        assertEq(
            _availableRewards,
            (((((timeOfLastUpdateLatest - timeOfLastUpdate) * 20)) * defaultRewardsPerUnitTime) / defaultTimeUnit) +
                (((((block.timestamp - timeOfLastUpdateLatest) * 10)) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    /*///////////////////////////////////////////////////////////////
            Unit tests: withdraw
            - same token-ids staked by stakers
    //////////////////////////////////////////////////////////////*/

    function test_state_withdraw_sameToken() public {
        //================ stake different tokens ======================
        vm.warp(1);

        vm.prank(stakerOne);
        stakeContract.stake(0, 50);

        vm.prank(stakerTwo);
        stakeContract.stake(0, 20);

        uint256 timeOfLastUpdate = block.timestamp;

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        // withdraw partially for stakerOne
        vm.prank(stakerOne);
        stakeContract.withdraw(0, 40);
        uint256 timeOfLastUpdateLatest = block.timestamp;

        // check balances/ownership after withdraw
        assertEq(erc1155.balanceOf(stakerOne, 0), 90);
        assertEq(erc1155.balanceOf(stakerTwo, 0), 80);
        assertEq(erc1155.balanceOf(address(stakeContract), 0), 10 + 20);

        // check available rewards after withdraw
        (, uint256 _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);
        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 50) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerTwo);
        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * 20) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check available rewards some time after withdraw
        vm.roll(200);
        vm.warp(2000);

        // check rewards for stakerOne
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerOne);

        assertEq(
            _availableRewards,
            (((((timeOfLastUpdateLatest - timeOfLastUpdate) * 50)) * defaultRewardsPerUnitTime) / defaultTimeUnit) +
                (((((block.timestamp - timeOfLastUpdateLatest) * 10)) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // withdraw partially for stakerTwo
        vm.prank(stakerTwo);
        stakeContract.withdraw(0, 10);
        timeOfLastUpdateLatest = block.timestamp;

        // check balances/ownership after withdraw
        assertEq(erc1155.balanceOf(stakerOne, 0), 90);
        assertEq(erc1155.balanceOf(stakerTwo, 0), 90);
        assertEq(erc1155.balanceOf(address(stakeContract), 0), 10 + 10);

        // check rewards for stakerTwo
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerTwo);

        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate) * 20)) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );

        // check rewards for stakerTwo after some time
        vm.roll(300);
        vm.warp(3000);
        (, _availableRewards) = stakeContract.getStakeInfoForToken(0, stakerTwo);

        assertEq(
            _availableRewards,
            (((((timeOfLastUpdateLatest - timeOfLastUpdate) * 20)) * defaultRewardsPerUnitTime) / defaultTimeUnit) +
                (((((block.timestamp - timeOfLastUpdateLatest) * 10)) * defaultRewardsPerUnitTime) / defaultTimeUnit)
        );
    }

    function test_revert_withdraw_withdrawingZeroTokens() public {
        vm.expectRevert("Withdrawing 0 tokens");
        stakeContract.withdraw(0, 0);
    }

    function test_revert_withdraw_withdrawingMoreThanStaked() public {
        // stake tokens
        vm.prank(stakerOne);
        stakeContract.stake(0, 50);

        vm.prank(stakerTwo);
        stakeContract.stake(1, 20);

        vm.prank(stakerTwo);
        stakeContract.stake(0, 20);

        // view staked tokens
        vm.roll(200);
        vm.warp(2000);
        (uint256[] memory _tokensStaked, uint256[] memory _tokenAmounts, uint256 _totalRewards) = stakeContract
            .getStakeInfo(stakerOne);

        console.log("==== staker one ====");
        for (uint256 i = 0; i < _tokensStaked.length; i++) {
            console.log(_tokensStaked[i], _tokenAmounts[i]);
        }

        (_tokensStaked, _tokenAmounts, _totalRewards) = stakeContract.getStakeInfo(stakerTwo);

        console.log("==== staker two ====");
        for (uint256 i = 0; i < _tokensStaked.length; i++) {
            console.log(_tokensStaked[i], _tokenAmounts[i]);
        }

        // trying to withdraw more than staked
        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(0, 60);

        // withdraw partially
        vm.prank(stakerOne);
        stakeContract.withdraw(0, 30);

        // trying to withdraw more than staked
        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(0, 60);

        // re-stake
        vm.prank(stakerOne);
        stakeContract.stake(0, 30);

        // trying to withdraw more than staked
        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(0, 60);

        // trying to withdraw different tokens
        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(1, 20);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_revert_zeroTimeUnit_adminLockTokens() public {
        //================ stake tokens
        vm.warp(1);

        // User stakes tokens
        vm.prank(stakerOne);
        stakeContract.stake(0, 50);

        // set default timeUnit to zero
        uint80 newTimeUnit = 0;
        vm.prank(deployer);
        vm.expectRevert("time-unit can't be 0");
        stakeContract.setDefaultTimeUnit(newTimeUnit);

        // set timeUnit to zero
        vm.prank(deployer);
        vm.expectRevert("time-unit can't be 0");
        stakeContract.setTimeUnit(0, newTimeUnit);

        // stakerOne and stakerTwo can withdraw their tokens
        // vm.expectRevert(stdError.divisionError);
        vm.prank(stakerOne);
        stakeContract.withdraw(0, 50);
    }

    function test_Macro_EditionDirectSafeTransferLocksToken() public {
        uint256 tokenId = 0;

        // stakerOne mistakenly safe-transfers direct to the staking contract
        vm.prank(stakerOne);
        vm.expectRevert("Direct transfer");
        erc1155.safeTransferFrom(stakerOne, address(stakeContract), tokenId, 100, "");

        // show that the transferred tokens were not properly staked
        // (uint256 tokensStaked, uint256 rewards) = stakeContract.getStakeInfoForToken(tokenId, stakerOne);
        // assertEq(0, tokensStaked);

        // // show that stakerOne cannot recover the tokens
        // vm.expectRevert();
        // vm.prank(stakerOne);
        // stakeContract.withdraw(tokenId, 100);
    }
}

contract Macro_EditionStakeTest is BaseTest {
    EditionStake internal stakeContract;

    uint256 internal defaultTimeUnit;
    uint256 internal defaultRewardsPerUnitTime;
    uint64 internal tokenAmount = 100;
    address internal stakerOne = address(0x345);
    address internal stakerTwo = address(0x567);

    function setUp() public override {
        super.setUp();

        defaultTimeUnit = 60;
        defaultRewardsPerUnitTime = 1;

        // mint erc1155 tokens to stakers
        erc1155.mint(stakerOne, 1, tokenAmount);
        erc1155.mint(stakerTwo, 2, tokenAmount);

        // mint reward tokens to contract admin
        erc20.mint(deployer, 1000 ether);

        stakeContract = EditionStake(payable(getContract("EditionStake")));

        // set approval
        vm.prank(stakerOne);
        erc1155.setApprovalForAll(address(stakeContract), true);
        vm.prank(stakerTwo);
        erc1155.setApprovalForAll(address(stakeContract), true);
    }

    // Demostrate setting unitTime to 0 locks the tokens irreversibly
    function testEdition_adminLockTokens() public {
        //================ stake tokens
        vm.warp(1);

        // Two users stake 1 tokens each
        vm.prank(stakerOne);
        stakeContract.stake(1, tokenAmount);
        vm.prank(stakerTwo);
        stakeContract.stake(2, tokenAmount);

        // set timeUnit to zero
        uint80 newTimeUnit = 0;
        vm.prank(deployer);
        vm.expectRevert("time-unit can't be 0");
        stakeContract.setDefaultTimeUnit(newTimeUnit);

        // stakerOne and stakerTwo can't withdraw their tokens
        // vm.expectRevert(stdError.divisionError);
        vm.prank(stakerOne);
        stakeContract.withdraw(1, tokenAmount);

        // vm.expectRevert(stdError.divisionError);
        vm.prank(stakerTwo);
        stakeContract.withdraw(2, tokenAmount);

        // timeUnit can't be changed back to a nonzero value
        newTimeUnit = 40;
        // vm.expectRevert(stdError.divisionError);
        vm.prank(deployer);
        stakeContract.setDefaultTimeUnit(newTimeUnit);
    }

    // Demostrate setting rewardsPerTimeUnit to a high value locks the tokens irreversibly
    function testEdition_demostrate_adminRewardsLock() public {
        //================ stake tokens
        vm.warp(1);

        // Two users stake 1 tokens each
        vm.prank(stakerOne);
        stakeContract.stake(1, tokenAmount);
        vm.prank(stakerTwo);
        stakeContract.stake(2, tokenAmount);

        // set rewardsPerTimeUnit to max value
        uint256 rewardsPerTimeUnit = type(uint256).max;
        vm.prank(deployer);
        stakeContract.setDefaultRewardsPerUnitTime(rewardsPerTimeUnit);

        vm.warp(1 days);

        // stakerOne and stakerTwo can't withdraw their tokens
        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(stakerOne);
        stakeContract.withdraw(1, tokenAmount);

        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(stakerTwo);
        stakeContract.withdraw(2, tokenAmount);

        // timeUnit can't be changed back
        rewardsPerTimeUnit = 60;
        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(deployer);
        stakeContract.setDefaultRewardsPerUnitTime(rewardsPerTimeUnit);
    }
}
