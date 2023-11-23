// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { NFTStake } from "contracts/prebuilts/staking/NFTStake.sol";

// Test imports

import "../utils/BaseTest.sol";

contract NFTStakeTest is BaseTest {
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
                            Unit tests: Stake
    //////////////////////////////////////////////////////////////*/

    function test_state_stake() public {
        //================ first staker ======================
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate_one = block.timestamp;

        // check balances/ownership of staked tokens
        for (uint256 i = 0; i < _tokenIdsOne.length; i++) {
            assertEq(erc721.ownerOf(_tokenIdsOne[i]), address(stakeContract));
            assertEq(stakeContract.stakerAddress(_tokenIdsOne[i]), stakerOne);
        }
        assertEq(erc721.balanceOf(stakerOne), 2);
        assertEq(erc721.balanceOf(address(stakeContract)), _tokenIdsOne.length);

        // check available rewards right after staking
        (uint256[] memory _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(_amountStaked.length, _tokenIdsOne.length);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(100);
        vm.warp(1000);

        // check available rewards after warp
        (, _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length) * rewardsPerUnitTime) / timeUnit)
        );

        //================ second staker ======================
        vm.roll(200);
        vm.warp(2000);
        uint256[] memory _tokenIdsTwo = new uint256[](2);
        _tokenIdsTwo[0] = 5;
        _tokenIdsTwo[1] = 6;

        // stake 2 tokens
        vm.prank(stakerTwo);
        stakeContract.stake(_tokenIdsTwo);
        uint256 timeOfLastUpdate_two = block.timestamp;

        // check balances/ownership of staked tokens
        for (uint256 i = 0; i < _tokenIdsTwo.length; i++) {
            assertEq(erc721.ownerOf(_tokenIdsTwo[i]), address(stakeContract));
            assertEq(stakeContract.stakerAddress(_tokenIdsTwo[i]), stakerTwo);
        }
        assertEq(erc721.balanceOf(stakerTwo), 3);
        assertEq(erc721.balanceOf(address(stakeContract)), _tokenIdsTwo.length + _tokenIdsOne.length);

        // check available rewards right after staking
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);

        assertEq(_amountStaked.length, _tokenIdsTwo.length);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(300);
        vm.warp(3000);

        // check available rewards for stakerOne
        (, _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length) * rewardsPerUnitTime) / timeUnit)
        );

        // check available rewards for stakerTwo
        (, _availableRewards) = stakeContract.getStakeInfo(stakerTwo);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_two) * _tokenIdsTwo.length) * rewardsPerUnitTime) / timeUnit)
        );
    }

    function test_revert_stake_stakingZeroTokens() public {
        // stake 0 tokens
        uint256[] memory _tokenIds;

        vm.prank(stakerOne);
        vm.expectRevert("Staking 0 tokens");
        stakeContract.stake(_tokenIds);
    }

    function test_revert_stake_notStaker() public {
        // stake unowned tokens
        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = 6;

        vm.prank(stakerOne);
        vm.expectRevert("ERC721: transfer from incorrect owner");
        stakeContract.stake(_tokenIds);
    }

    /*///////////////////////////////////////////////////////////////
                            Unit tests: claimRewards
    //////////////////////////////////////////////////////////////*/

    function test_state_claimRewards() public {
        //================ first staker ======================
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);
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
            ((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length) * rewardsPerUnitTime) / timeUnit)
        );
        assertEq(
            rewardBalanceAfter,
            rewardBalanceBefore -
                ((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length) * rewardsPerUnitTime) / timeUnit)
        );

        // check available rewards after claiming
        (uint256[] memory _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(_amountStaked.length, _tokenIdsOne.length);
        assertEq(_availableRewards, 0);
    }

    function test_revert_claimRewards_noRewards() public {
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);

        //=================== try to claim rewards in same block

        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        stakeContract.claimRewards();

        //======= withdraw tokens and claim rewards
        vm.roll(100);
        vm.warp(1000);

        vm.prank(stakerOne);
        stakeContract.withdraw(_tokenIdsOne);
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

    function test_state_setRewardsPerUnitTime() public {
        // check current value
        assertEq(rewardsPerUnitTime, stakeContract.getRewardsPerUnitTime());

        // set new value and check
        uint256 newRewardsPerUnitTime = 50;
        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(newRewardsPerUnitTime);
        assertEq(newRewardsPerUnitTime, stakeContract.getRewardsPerUnitTime());

        //================ stake tokens
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(200);
        assertEq(200, stakeContract.getRewardsPerUnitTime());
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for rewardsPerUnitTime for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * _tokenIdsOne.length) * newRewardsPerUnitTime) / timeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * _tokenIdsOne.length) * 200) / timeUnit)
        );
    }

    function test_revert_setRewardsPerUnitTime_notAuthorized() public {
        vm.expectRevert("Not authorized");
        stakeContract.setRewardsPerUnitTime(1);
    }

    function test_state_setTimeUnit() public {
        // check current value
        assertEq(timeUnit, stakeContract.getTimeUnit());

        // set new value and check
        uint256 newTimeUnit = 2 minutes;
        vm.prank(deployer);
        stakeContract.setTimeUnit(newTimeUnit);
        assertEq(newTimeUnit, stakeContract.getTimeUnit());

        //================ stake tokens
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        vm.prank(deployer);
        stakeContract.setTimeUnit(1 seconds);
        assertEq(1 seconds, stakeContract.getTimeUnit());
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for rewardsPerUnitTime for calculation
        (, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * _tokenIdsOne.length) * rewardsPerUnitTime) / newTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _newRewards,
            _availableRewards +
                ((((block.timestamp - newTimeOfLastUpdate) * _tokenIdsOne.length) * rewardsPerUnitTime) / (1 seconds))
        );
    }

    function test_revert_setTimeUnit_notAuthorized() public {
        vm.expectRevert("Not authorized");
        stakeContract.setTimeUnit(1);
    }

    /*///////////////////////////////////////////////////////////////
                            Unit tests: withdraw
    //////////////////////////////////////////////////////////////*/

    function test_state_withdraw() public {
        //================ first staker ======================
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate = block.timestamp;

        // check balances/ownership of staked tokens
        for (uint256 i = 0; i < _tokenIdsOne.length; i++) {
            assertEq(erc721.ownerOf(_tokenIdsOne[i]), address(stakeContract));
            assertEq(stakeContract.stakerAddress(_tokenIdsOne[i]), stakerOne);
        }
        assertEq(erc721.balanceOf(stakerOne), 2);
        assertEq(erc721.balanceOf(address(stakeContract)), _tokenIdsOne.length);

        // check available rewards right after staking
        (uint256[] memory _amountStaked, uint256 _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(_amountStaked.length, _tokenIdsOne.length);
        assertEq(_availableRewards, 0);

        console.log("==== staked tokens before withdraw ====");
        for (uint256 i = 0; i < _amountStaked.length; i++) {
            console.log(_amountStaked[i]);
        }

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        uint256[] memory _tokensToWithdraw = new uint256[](1);
        _tokensToWithdraw[0] = 1;

        vm.prank(stakerOne);
        stakeContract.withdraw(_tokensToWithdraw);

        // check balances/ownership after withdraw
        for (uint256 i = 0; i < _tokensToWithdraw.length; i++) {
            assertEq(erc721.ownerOf(_tokensToWithdraw[i]), stakerOne);
            assertEq(stakeContract.stakerAddress(_tokensToWithdraw[i]), address(0));
        }
        assertEq(erc721.balanceOf(stakerOne), 3);
        assertEq(erc721.balanceOf(address(stakeContract)), 2);

        // check available rewards after withdraw
        (_amountStaked, _availableRewards) = stakeContract.getStakeInfo(stakerOne);
        assertEq(_availableRewards, ((((block.timestamp - timeOfLastUpdate) * 3) * rewardsPerUnitTime) / timeUnit));

        console.log("==== staked tokens after withdraw ====");
        for (uint256 i = 0; i < _amountStaked.length; i++) {
            console.log(_amountStaked[i]);
        }

        uint256 timeOfLastUpdateLatest = block.timestamp;

        // check available rewards some time after withdraw
        vm.roll(200);
        vm.warp(2000);

        (, _availableRewards) = stakeContract.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            (((((timeOfLastUpdateLatest - timeOfLastUpdate) * 3)) * rewardsPerUnitTime) / timeUnit) +
                (((((block.timestamp - timeOfLastUpdateLatest) * 2)) * rewardsPerUnitTime) / timeUnit)
        );

        // stake again
        vm.prank(stakerOne);
        stakeContract.stake(_tokensToWithdraw);

        _tokensToWithdraw[0] = 5;
        vm.prank(stakerTwo);
        stakeContract.stake(_tokensToWithdraw);
        // check available rewards after re-staking
        (_amountStaked, ) = stakeContract.getStakeInfo(stakerOne);

        console.log("==== staked tokens after re-staking ====");
        for (uint256 i = 0; i < _amountStaked.length; i++) {
            console.log(_amountStaked[i]);
        }
    }

    function test_revert_withdraw_withdrawingZeroTokens() public {
        uint256[] memory _tokensToWithdraw;

        vm.expectRevert("Withdrawing 0 tokens");
        stakeContract.withdraw(_tokensToWithdraw);
    }

    function test_revert_withdraw_notStaker() public {
        // stake tokens
        uint256[] memory _tokenIds = new uint256[](2);
        _tokenIds[0] = 0;
        _tokenIds[1] = 1;

        vm.prank(stakerOne);
        stakeContract.stake(_tokenIds);

        // trying to withdraw zero tokens
        uint256[] memory _tokensToWithdraw = new uint256[](1);
        _tokensToWithdraw[0] = 2;

        vm.prank(stakerOne);
        vm.expectRevert("Not staker");
        stakeContract.withdraw(_tokensToWithdraw);
    }

    function test_revert_withdraw_withdrawingMoreThanStaked() public {
        // stake tokens
        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = 0;

        vm.prank(stakerOne);
        stakeContract.stake(_tokenIds);

        // trying to withdraw tokens not staked by caller
        uint256[] memory _tokensToWithdraw = new uint256[](2);
        _tokensToWithdraw[0] = 0;
        _tokensToWithdraw[1] = 1;

        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        stakeContract.withdraw(_tokensToWithdraw);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_revert_zeroTimeUnit_adminLockTokens() public {
        //================ stake tokens
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](1);
        uint256[] memory _tokenIdsTwo = new uint256[](1);
        _tokenIdsOne[0] = 0;
        _tokenIdsTwo[0] = 5;

        // Two different users stake 1 tokens each
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);
        vm.prank(stakerTwo);
        stakeContract.stake(_tokenIdsTwo);

        // set timeUnit to zero
        uint256 newTimeUnit = 0;
        vm.prank(deployer);
        vm.expectRevert("time-unit can't be 0");
        stakeContract.setTimeUnit(newTimeUnit);

        // stakerOne and stakerTwo can withdraw their tokens
        // vm.expectRevert(stdError.divisionError);
        vm.prank(stakerOne);
        stakeContract.withdraw(_tokenIdsOne);

        // vm.expectRevert(stdError.divisionError);
        vm.prank(stakerTwo);
        stakeContract.withdraw(_tokenIdsTwo);
    }

    function test_revert_largeRewardsPerUnitTime_adminRewardsLock() public {
        //================ stake tokens
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](1);
        uint256[] memory _tokenIdsTwo = new uint256[](1);

        uint256 stakerOneToken = erc721.nextTokenIdToMint();
        erc721.mint(stakerOne, 5); // mint token id 0 to 4
        uint256 stakerTwoToken = erc721.nextTokenIdToMint();
        erc721.mint(stakerTwo, 5); // mint token id 5 to 9
        _tokenIdsOne[0] = stakerOneToken;
        _tokenIdsTwo[0] = stakerTwoToken;

        // Two users stake 1 tokens each
        vm.prank(stakerOne);
        stakeContract.stake(_tokenIdsOne);
        vm.prank(stakerTwo);
        stakeContract.stake(_tokenIdsTwo);

        // set rewardsPerTimeUnit to max value
        uint256 rewardsPerTimeUnit = type(uint256).max;
        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(rewardsPerTimeUnit);

        vm.warp(1 days);

        // stakerOne and stakerTwo can't withdraw their tokens
        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(stakerOne);
        stakeContract.withdraw(_tokenIdsOne);

        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(stakerTwo);
        stakeContract.withdraw(_tokenIdsTwo);

        // rewardsPerTimeUnit can't be changed
        rewardsPerTimeUnit = 60;
        // vm.expectRevert(stdError.arithmeticError);
        vm.prank(deployer);
        stakeContract.setRewardsPerUnitTime(rewardsPerTimeUnit);
    }

    function test_Macro_NFTDirectSafeTransferLocksToken() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        // stakerOne mistakenly safe-transfers direct to the staking contract
        vm.prank(stakerOne);
        vm.expectRevert("Direct transfer");
        erc721.safeTransferFrom(stakerOne, address(stakeContract), tokenIds[0]);

        // show that the transferred token was not properly staked
        // (uint256[] memory tokensStaked, uint256 rewards) = stakeContract.getStakeInfo(stakerOne);
        // assertEq(0, tokensStaked.length);

        // // show that stakerOne cannot recover the token
        // vm.expectRevert();
        // vm.prank(stakerOne);
        // stakeContract.withdraw(tokenIds);
    }
}
