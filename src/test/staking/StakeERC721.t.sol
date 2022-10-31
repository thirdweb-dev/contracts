// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/staking/StakeERC721.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import { BaseTest, MockERC20 } from "../utils/BaseTest.sol";

contract StakeERC721Test is BaseTest {
    StakeERC721 internal stake;

    address internal stakerOne;
    address internal stakerTwo;
    address internal stakerThree;
    address internal stakerFour;

    MockERC20 public rewardOne;
    MockERC20 public rewardTwo;
    MockERC20 public rewardThree;

    StakeERC721.RewardToken[] internal rewardTokens;

    function setUp() public override {
        super.setUp();

        stakerOne = getActor(1);
        stakerTwo = getActor(2);
        stakerThree = getActor(3);
        stakerFour = getActor(4);

        rewardOne = new MockERC20();
        rewardTwo = new MockERC20();
        rewardThree = new MockERC20();

        rewardTokens.push(StakeERC721.RewardToken({ assetContract: address(rewardOne), rewardAmount: 10 }));
        rewardTokens.push(StakeERC721.RewardToken({ assetContract: address(rewardTwo), rewardAmount: 20 }));
        rewardTokens.push(StakeERC721.RewardToken({ assetContract: address(rewardThree), rewardAmount: 30 }));

        vm.prank(deployer);
        stake = new StakeERC721(erc721, rewardTokens);
    }

    function test_state_stake() public {}
}
