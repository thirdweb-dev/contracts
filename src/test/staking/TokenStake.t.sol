// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenStake } from "contracts/prebuilts/staking/TokenStake.sol";

// Test imports

import "../utils/BaseTest.sol";

contract TokenStakeTest is BaseTest {
    TokenStake internal stakeContract;

    address internal stakerOne;
    address internal stakerTwo;

    uint80 internal timeUnit;
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

        uint256 rewardBalanceBefore = stakeContract.getRewardTokenBalance();
        vm.prank(stakerOne);
        stakeContract.claimRewards();
        uint256 rewardBalanceAfter = stakeContract.getRewardTokenBalance();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerOne),
            (((((block.timestamp - timeOfLastUpdate_one) * 400) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );
        assertEq(
            rewardBalanceAfter,
            rewardBalanceBefore -
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

        rewardBalanceBefore = stakeContract.getRewardTokenBalance();
        vm.prank(stakerTwo);
        stakeContract.claimRewards();
        rewardBalanceAfter = stakeContract.getRewardTokenBalance();

        // check reward balances
        assertEq(
            erc20.balanceOf(stakerTwo),
            (((((block.timestamp - timeOfLastUpdate_two) * 200) * rewardRatioNumerator) / timeUnit) /
                rewardRatioDenominator)
        );
        assertEq(
            rewardBalanceAfter,
            rewardBalanceBefore -
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
        (uint256 numerator, uint256 denominator) = stakeContract.getRewardRatio();
        assertEq(3, numerator);
        assertEq(70, denominator);

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
        (numerator, denominator) = stakeContract.getRewardRatio();
        assertEq(3, numerator);
        assertEq(80, denominator);
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
        uint80 timeUnitToSet = 100;
        vm.prank(deployer);
        stakeContract.setTimeUnit(timeUnitToSet);
        assertEq(timeUnitToSet, stakeContract.getTimeUnit());

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
        assertEq(200, stakeContract.getTimeUnit());
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for timeUnit for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            (((((block.timestamp - timeOfLastUpdate) * 400) * rewardRatioNumerator) / timeUnitToSet) /
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

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_revert_zeroTimeUnit_adminLockTokens() public {
        //================ stake tokens
        vm.warp(1);

        // User stakes tokens
        vm.prank(stakerOne);
        stakeContract.stake(400);

        // set timeUnit to zero
        uint80 newTimeUnit = 0;
        vm.prank(deployer);
        vm.expectRevert("time-unit can't be 0");
        stakeContract.setTimeUnit(newTimeUnit);

        // stakerOne and stakerTwo can withdraw their tokens
        // vm.expectRevert(stdError.divisionError);
        vm.prank(stakerOne);
        stakeContract.withdraw(400);
    }
}

contract MockERC20Decimals is MockERC20 {
    uint8 private immutable DECIMALS;

    constructor(uint8 _decimals) MockERC20() {
        DECIMALS = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
}

// Test scenario where reward token has 6 decimals and staking token has 18
contract Macro_TokenStake_Rewards6_Staking18_Test is BaseTest {
    MockERC20Decimals public erc20_reward6;
    MockERC20Decimals public erc20_staking18;

    TokenStake internal stakeContract_reward6_staking18;

    address internal stakerOne;

    uint80 internal timeUnit;
    uint256 internal rewardRatioNumerator;
    uint256 internal rewardRatioDenominator;

    function setUp() public override {
        super.setUp();

        erc20_reward6 = new MockERC20Decimals(6);
        erc20_staking18 = new MockERC20Decimals(18);

        // every 60s earns 1 reward token per 2 tokens staked
        timeUnit = 60;
        rewardRatioNumerator = 1;
        rewardRatioDenominator = 2;

        deployContractProxy(
            "TokenStake",
            abi.encodeCall(
                TokenStake.initialize,
                (
                    deployer,
                    CONTRACT_URI,
                    forwarders(),
                    address(erc20_reward6),
                    address(erc20_staking18),
                    timeUnit,
                    rewardRatioNumerator,
                    rewardRatioDenominator
                )
            )
        );

        stakeContract_reward6_staking18 = TokenStake(payable(getContract("TokenStake")));

        stakerOne = address(0x345);

        // mint 1000 tokens to stakerOne
        erc20_staking18.mint(stakerOne, 1000e18);

        // mint 1000 reward tokens to contract admin
        erc20_reward6.mint(deployer, 1000e6);

        // set approvals
        vm.prank(stakerOne);
        erc20_staking18.approve(address(stakeContract_reward6_staking18), type(uint256).max);

        // transfer 100 reward tokens
        vm.startPrank(deployer);
        erc20_reward6.approve(address(stakeContract_reward6_staking18), type(uint256).max);
        // erc20_reward6.transfer(address(stakeContract_reward6_staking18), 100e6);
        stakeContract_reward6_staking18.depositRewardTokens(100e6);
        vm.stopPrank();
    }

    //===== Reward Token 6 Decimals, Staking Token 18 Decimals =====//
    function test_Macro_reward6_staking18() public {
        vm.warp(1);

        // stake 400 tokens
        vm.prank(stakerOne);
        stakeContract_reward6_staking18.stake(400e18);
        uint256 timeOfLastUpdate = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc20_staking18.balanceOf(address(stakeContract_reward6_staking18)), 400e18);
        assertEq(erc20_staking18.balanceOf(address(stakerOne)), 600e18);

        // check available rewards right after staking
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract_reward6_staking18.getStakeInfo(stakerOne);

        assertEq(_amountStaked, 400e18);
        assertEq(_availableRewards, 0);

        //=================== warp ahead exactly 1 timeUnit: 60s
        vm.roll(4);
        vm.warp(61);
        assertEq(timeUnit, block.timestamp - timeOfLastUpdate);

        // With 400 tokens staked, we expect 200 reward tokens earned
        (, _availableRewards) = stakeContract_reward6_staking18.getStakeInfo(stakerOne);
        console2.log("Expect 200 reward tokens. Amount earned: ", _availableRewards / 1e6);
        assertEq(_availableRewards, 200e6);
    }
}

// Test scenario where reward token has 18 decimals and staking token has 6
contract Macro_TokenStake_Rewards18_Staking6_Test is BaseTest {
    MockERC20Decimals public erc20_reward18;
    MockERC20Decimals public erc20_staking6;

    TokenStake internal stakeContract_reward18_staking6;

    address internal stakerOne;

    uint80 internal timeUnit;
    uint256 internal rewardRatioNumerator;
    uint256 internal rewardRatioDenominator;

    function setUp() public override {
        super.setUp();

        erc20_reward18 = new MockERC20Decimals(18);
        erc20_staking6 = new MockERC20Decimals(6);

        // every 60s earns 1 reward token per 2 tokens staked
        timeUnit = 60;
        rewardRatioNumerator = 1;
        rewardRatioDenominator = 2;

        deployContractProxy(
            "TokenStake",
            abi.encodeCall(
                TokenStake.initialize,
                (
                    deployer,
                    CONTRACT_URI,
                    forwarders(),
                    address(erc20_reward18),
                    address(erc20_staking6),
                    timeUnit,
                    rewardRatioNumerator,
                    rewardRatioDenominator
                )
            )
        );

        stakeContract_reward18_staking6 = TokenStake(payable(getContract("TokenStake")));

        stakerOne = address(0x345);

        // mint 1000 tokens to stakerOne
        erc20_staking6.mint(stakerOne, 1000e6);

        // mint 1000 reward tokens to contract admin
        erc20_reward18.mint(deployer, 1000e18);

        // set approvals
        vm.prank(stakerOne);
        erc20_staking6.approve(address(stakeContract_reward18_staking6), type(uint256).max);

        // transfer 100 reward tokens
        vm.startPrank(deployer);
        erc20_reward18.approve(address(stakeContract_reward18_staking6), type(uint256).max);
        // erc20_reward18.transfer(address(stakeContract_reward18_staking6), 100e18);
        stakeContract_reward18_staking6.depositRewardTokens(100e18);
        vm.stopPrank();
    }

    //===== Reward Token 18 Decimals, Staking Token 6 Decimals =====//
    function test_Macro_reward18_staking6() public {
        vm.warp(1);

        // stake 400 tokens
        vm.prank(stakerOne);
        stakeContract_reward18_staking6.stake(400e6);
        uint256 timeOfLastUpdate = block.timestamp;

        // check balances/ownership of staked tokens
        assertEq(erc20_staking6.balanceOf(address(stakeContract_reward18_staking6)), 400e6);
        assertEq(erc20_staking6.balanceOf(address(stakerOne)), 600e6);

        // check available rewards right after staking
        (uint256 _amountStaked, uint256 _availableRewards) = stakeContract_reward18_staking6.getStakeInfo(stakerOne);

        assertEq(_amountStaked, 400e6);
        assertEq(_availableRewards, 0);

        //=================== warp ahead exactly 1 timeUnit: 60s
        vm.roll(4);
        vm.warp(61);
        assertEq(timeUnit, block.timestamp - timeOfLastUpdate);

        // With 400 tokens staked, we expect 200 reward tokens earned
        (, _availableRewards) = stakeContract_reward18_staking6.getStakeInfo(stakerOne);
        console2.log("Expect 200 reward tokens. Amount earned: ", _availableRewards / 1e18);
        assertEq(_availableRewards, 200e18);
    }
}

contract Macro_TokenStakeTest is BaseTest {
    TokenStake internal stakeContract;

    uint80 internal timeUnit;
    uint256 internal rewardsPerUnitTime;
    uint256 internal rewardRatioNumerator;
    uint256 internal rewardRatioDenominator;
    uint256 internal tokenAmount = 100;
    address internal stakerOne = address(0x345);
    address internal stakerTwo = address(0x567);

    function setUp() public override {
        super.setUp();

        timeUnit = 60;
        rewardRatioNumerator = 3;
        rewardRatioDenominator = 50;
        // mint 1000 tokens to stakerOne
        erc20Aux.mint(stakerOne, tokenAmount);
        // mint 1000 tokens to stakerOne
        erc20Aux.mint(stakerTwo, tokenAmount);
        // mint reward tokens to contract admin
        erc20.mint(deployer, 1000 ether);

        stakeContract = TokenStake(payable(getContract("TokenStake")));

        // set approvals
        vm.prank(stakerOne);
        erc20Aux.approve(address(stakeContract), type(uint256).max);
        vm.prank(stakerTwo);
        erc20Aux.approve(address(stakeContract), type(uint256).max);

        vm.startPrank(deployer);
        erc20.approve(address(stakeContract), type(uint256).max);
        // erc20.transfer(address(stakeContract), 100 ether);
        stakeContract.depositRewardTokens(100 ether);
        vm.stopPrank();
    }

    // Demostrate setting unitTime to 0 locks the tokens irreversibly
    function testToken_adminLockTokens() public {
        //================ stake tokens
        vm.warp(1);

        // Two users stake 1 tokens each
        vm.prank(stakerOne);
        stakeContract.stake(tokenAmount);
        vm.prank(stakerTwo);
        stakeContract.stake(tokenAmount);

        // set timeUnit to zero
        uint80 newTimeUnit = 0;
        vm.prank(deployer);
        vm.expectRevert("time-unit can't be 0");
        stakeContract.setTimeUnit(newTimeUnit);
    }

    function testToken_demostrate_adminRewardsLock() public {
        //================ stake tokens
        vm.warp(1);
        // Two users stake 1 tokens each
        vm.prank(stakerOne);
        stakeContract.stake(tokenAmount);
        vm.prank(stakerTwo);
        stakeContract.stake(tokenAmount);

        // set timeUnit to a fraction of uint256 maximum value
        uint256 newRewardsPerTimeUnit = type(uint256).max / 100;
        vm.prank(deployer);
        stakeContract.setRewardRatio(newRewardsPerTimeUnit, 1);

        vm.warp(1 days);

        // stakerOne and stakerTwo can't withdraw their tokens
        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(stakerOne);
        stakeContract.withdraw(tokenAmount);

        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(stakerTwo);
        stakeContract.withdraw(tokenAmount);

        // rewardRatio can't be changed back
        newRewardsPerTimeUnit = 60;
        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(deployer);
        stakeContract.setRewardRatio(newRewardsPerTimeUnit, 1);
    }
}

contract Macro_TokenStake_Tax is BaseTest {
    TokenStake internal stakeContract;
    uint256 internal tokenAmount = 100 ether;
    address internal stakerOne = address(0x345);
    address internal stakerTwo = address(0x567);

    function setUp() public override {
        super.setUp();

        stakeContract = TokenStake(payable(getContract("TokenStake")));

        // mint reward tokens to contract admin
        erc20.mint(deployer, tokenAmount);
        // mint 100 tokens to stakers
        erc20Aux.mint(stakerOne, tokenAmount);
        erc20Aux.mint(stakerTwo, tokenAmount);

        // Activate Mock tax
        erc20Aux.toggleTax();

        vm.prank(stakerOne);
        erc20Aux.approve(address(stakeContract), type(uint256).max);

        vm.startPrank(deployer);
        erc20.approve(address(stakeContract), type(uint256).max);
        // erc20.transfer(address(stakeContract), 100 ether);
        stakeContract.depositRewardTokens(100 ether);
        vm.stopPrank();
    }

    // Demonstrate griefer can drain staked tokens for other users
    function testToken_demonstrate_inaccurate_amount() public {
        // First user stakes 100 tokens
        vm.prank(stakerOne);
        stakeContract.stake(tokenAmount);

        // Since there is 10% tax only 90 should be in the contract
        uint256 stakingTokenBalance = erc20Aux.balanceOf(address(stakeContract));
        assertEq(stakingTokenBalance, 90 ether);
        // Assert the amount was correctly assigned
        (uint256 stakingTokenAmount, ) = stakeContract.getStakeInfo(stakerOne);
        assertEq(stakingTokenAmount, 90 ether);

        // Users stake and withdraw tokens, draining other users staked balances
        // for (uint256 i = 1; i <= 9; i++) {
        //     address staker = vm.addr(i);
        //     erc20Aux.mint(staker, tokenAmount);
        //     vm.startPrank(staker);
        //     erc20Aux.approve(address(stakeContract), type(uint256).max);
        //     stakeContract.stake(tokenAmount);
        //     stakeContract.withdraw(tokenAmount);
        //     vm.stopPrank();
        // }

        // // Staked amount still remains unchanged for stakerOne
        // (stakingTokenAmount, ) = stakeContract.getStakeInfo(stakerOne);
        // assertEq(stakingTokenAmount, 100 ether);

        // // However there are no tokens left in the contract
        // stakingTokenBalance = erc20Aux.balanceOf(address(stakeContract));
        // assertEq(stakingTokenBalance, 0 ether);

        // // StakerOne can't withdraw since there is no balance left
        // vm.expectRevert("ERC20: transfer amount exceeds balance");
        // vm.prank(stakerOne);
        // stakeContract.withdraw(stakingTokenAmount);
    }
}
