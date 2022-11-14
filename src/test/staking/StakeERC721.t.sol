// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// import { StakeERC721 } from "contracts/staking/StakeERC721.sol";

// // Test imports
// import "contracts/lib/TWStrings.sol";
// import "../utils/BaseTest.sol";

// contract StakeERC721Test is BaseTest {
//     StakeERC721 internal stakeContract;

//     address internal stakerOne;
//     address internal stakerTwo;
//     address internal stakerThree;
//     address internal stakerFour;

//     MockERC20[] public rewardAssets;

//     StakeERC721.RewardToken[] internal rewardTokens;

//     function setUp() public override {
//         super.setUp();

//         stakerOne = getActor(1);
//         stakerTwo = getActor(2);
//         stakerThree = getActor(3);
//         stakerFour = getActor(4);

//         for (uint256 i = 0; i < 3; i++) {
//             rewardAssets.push(new MockERC20());
//             rewardTokens.push(
//                 StakeERC721.RewardToken({ assetContract: address(rewardAssets[i]), rewardAmount: 10 + i * 10 })
//             );
//         }

//         vm.prank(deployer);
//         stakeContract = new StakeERC721(erc721, rewardTokens);

//         for (uint256 i = 0; i < 3; i++) {
//             rewardAssets[i].mint(address(stakeContract), 1000 ether);
//         }

//         erc721.mint(address(stakerOne), 5);
//         erc721.mint(address(stakerTwo), 5);
//         erc721.mint(address(stakerThree), 5);
//         erc721.mint(address(stakerFour), 5);

//         vm.prank(address(stakerOne));
//         erc721.setApprovalForAll(address(stakeContract), true);
//         vm.prank(stakerTwo);
//         erc721.setApprovalForAll(address(stakeContract), true);
//         vm.prank(stakerThree);
//         erc721.setApprovalForAll(address(stakeContract), true);
//         vm.prank(stakerFour);
//         erc721.setApprovalForAll(address(stakeContract), true);
//     }

//     /*///////////////////////////////////////////////////////////////
//                             Unit tests: Stake
//     //////////////////////////////////////////////////////////////*/

//     function test_state_stake() public {
//         //================ first staker ======================
//         vm.warp(1);
//         uint256[] memory _tokenIdsOne = new uint256[](3);
//         _tokenIdsOne[0] = 0;
//         _tokenIdsOne[1] = 1;
//         _tokenIdsOne[2] = 2;

//         // stake 3 tokens
//         vm.prank(address(stakerOne));
//         stakeContract.stake(_tokenIdsOne);
//         uint256 timeOfLastUpdate_one = block.timestamp;

//         // check balances/ownership of staked tokens
//         for (uint256 i = 0; i < _tokenIdsOne.length; i++) {
//             assertEq(erc721.ownerOf(_tokenIdsOne[i]), address(stakeContract));
//             assertEq(stakeContract.stakerAddress(_tokenIdsOne[i]), address(stakerOne));
//         }
//         assertEq(erc721.balanceOf(address(stakerOne)), 2);
//         assertEq(erc721.balanceOf(address(stakeContract)), _tokenIdsOne.length);

//         // check available rewards right after staking
//         (uint256 _amountStaked, StakeERC721.RewardToken[] memory _availableRewards) = stakeContract.userStakeInfo(
//             address(stakerOne)
//         );

//         assertEq(_amountStaked, _tokenIdsOne.length);
//         assertEq(_availableRewards.length, rewardAssets.length);
//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(_availableRewards[i].rewardAmount, 0);
//         }

//         //=================== warp timestamp to calculate rewards
//         vm.roll(100);
//         vm.warp(1000);

//         // check available rewards after warp
//         (, _availableRewards) = stakeContract.userStakeInfo(address(stakerOne));

//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(
//                 _availableRewards[i].rewardAmount,
//                 (((((block.timestamp - timeOfLastUpdate_one) * 3)) * rewardTokens[i].rewardAmount) / 3600)
//             );
//         }

//         //================ second staker ======================
//         vm.roll(200);
//         vm.warp(2000);
//         uint256[] memory _tokenIdsTwo = new uint256[](2);
//         _tokenIdsTwo[0] = 5;
//         _tokenIdsTwo[1] = 6;

//         // stake 2 tokens
//         vm.prank(address(stakerTwo));
//         stakeContract.stake(_tokenIdsTwo);
//         uint256 timeOfLastUpdate_two = block.timestamp;

//         // check balances/ownership of staked tokens
//         for (uint256 i = 0; i < _tokenIdsTwo.length; i++) {
//             assertEq(erc721.ownerOf(_tokenIdsTwo[i]), address(stakeContract));
//             assertEq(stakeContract.stakerAddress(_tokenIdsTwo[i]), address(stakerTwo));
//         }
//         assertEq(erc721.balanceOf(address(stakerTwo)), 3);
//         assertEq(erc721.balanceOf(address(stakeContract)), _tokenIdsTwo.length + _tokenIdsOne.length);

//         // check available rewards right after staking
//         (_amountStaked, _availableRewards) = stakeContract.userStakeInfo(address(stakerTwo));

//         assertEq(_amountStaked, _tokenIdsTwo.length);
//         assertEq(_availableRewards.length, rewardAssets.length);
//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(_availableRewards[i].rewardAmount, 0);
//         }

//         //=================== warp timestamp to calculate rewards
//         vm.roll(300);
//         vm.warp(3000);

//         // check available rewards for stakerOne
//         (, _availableRewards) = stakeContract.userStakeInfo(address(stakerOne));

//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(
//                 _availableRewards[i].rewardAmount,
//                 (((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length)) * rewardTokens[i].rewardAmount) /
//                     3600)
//             );
//         }

//         // check available rewards for stakerTwo
//         (, _availableRewards) = stakeContract.userStakeInfo(address(stakerTwo));

//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(
//                 _availableRewards[i].rewardAmount,
//                 (((((block.timestamp - timeOfLastUpdate_two) * _tokenIdsTwo.length)) * rewardTokens[i].rewardAmount) /
//                     3600)
//             );
//         }
//     }

//     /*///////////////////////////////////////////////////////////////
//                             Unit tests: claimRewards
//     //////////////////////////////////////////////////////////////*/

//     function test_state_claimRewards() public {
//         //================ first staker ======================
//         vm.warp(1);
//         uint256[] memory _tokenIdsOne = new uint256[](3);
//         _tokenIdsOne[0] = 0;
//         _tokenIdsOne[1] = 1;
//         _tokenIdsOne[2] = 2;

//         // stake 3 tokens
//         vm.prank(address(stakerOne));
//         stakeContract.stake(_tokenIdsOne);
//         uint256 timeOfLastUpdate_one = block.timestamp;

//         //=================== warp timestamp to claim rewards
//         vm.roll(100);
//         vm.warp(1000);

//         vm.prank(address(stakerOne));
//         stakeContract.claimRewards();

//         // check reward balances
//         for (uint256 i = 0; i < rewardTokens.length; i++) {
//             assertEq(
//                 rewardAssets[i].balanceOf(address(stakerOne)),
//                 (((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length)) * rewardTokens[i].rewardAmount) /
//                     3600)
//             );
//         }

//         // check available rewards after claiming
//         (uint256 _amountStaked, StakeERC721.RewardToken[] memory _availableRewards) = stakeContract.userStakeInfo(
//             address(stakerOne)
//         );

//         assertEq(_amountStaked, _tokenIdsOne.length);
//         assertEq(_availableRewards.length, rewardAssets.length);
//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(_availableRewards[i].rewardAmount, 0);
//         }
//     }

//     /*///////////////////////////////////////////////////////////////
//                             Unit tests: withdraw
//     //////////////////////////////////////////////////////////////*/

//     function test_state_withdraw() public {
//         //================ first staker ======================
//         vm.warp(1);
//         uint256[] memory _tokenIdsOne = new uint256[](3);
//         _tokenIdsOne[0] = 0;
//         _tokenIdsOne[1] = 1;
//         _tokenIdsOne[2] = 2;

//         // stake 3 tokens
//         vm.prank(address(stakerOne));
//         stakeContract.stake(_tokenIdsOne);
//         uint256 timeOfLastUpdate = block.timestamp;

//         // check balances/ownership of staked tokens
//         for (uint256 i = 0; i < _tokenIdsOne.length; i++) {
//             assertEq(erc721.ownerOf(_tokenIdsOne[i]), address(stakeContract));
//             assertEq(stakeContract.stakerAddress(_tokenIdsOne[i]), address(stakerOne));
//         }
//         assertEq(erc721.balanceOf(address(stakerOne)), 2);
//         assertEq(erc721.balanceOf(address(stakeContract)), _tokenIdsOne.length);

//         // check available rewards right after staking
//         (uint256 _amountStaked, StakeERC721.RewardToken[] memory _availableRewards) = stakeContract.userStakeInfo(
//             address(stakerOne)
//         );

//         assertEq(_amountStaked, _tokenIdsOne.length);
//         assertEq(_availableRewards.length, rewardAssets.length);
//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(_availableRewards[i].rewardAmount, 0);
//         }

//         //========== warp timestamp before withdraw
//         vm.roll(100);
//         vm.warp(1000);

//         uint256[] memory _tokensToWithdraw = new uint256[](2);
//         _tokensToWithdraw[0] = 2;
//         _tokensToWithdraw[1] = 0;

//         vm.prank(address(stakerOne));
//         stakeContract.withdraw(_tokensToWithdraw);

//         // check balances/ownership after withdraw
//         for (uint256 i = 0; i < _tokensToWithdraw.length; i++) {
//             assertEq(erc721.ownerOf(_tokensToWithdraw[i]), address(stakerOne));
//             assertEq(stakeContract.stakerAddress(_tokensToWithdraw[i]), address(0));
//         }
//         assertEq(erc721.balanceOf(address(stakerOne)), 4);
//         assertEq(erc721.balanceOf(address(stakeContract)), 1);

//         // check available rewards after withdraw
//         (, _availableRewards) = stakeContract.userStakeInfo(address(stakerOne));

//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(
//                 _availableRewards[i].rewardAmount,
//                 (((((block.timestamp - timeOfLastUpdate) * 3)) * rewardTokens[i].rewardAmount) / 3600)
//             );
//         }

//         uint256 timeOfLastUpdateLatest = block.timestamp;

//         // check available rewards some time after withdraw
//         vm.roll(200);
//         vm.warp(2000);

//         (, _availableRewards) = stakeContract.userStakeInfo(address(stakerOne));

//         for (uint256 i = 0; i < _availableRewards.length; i++) {
//             assertEq(_availableRewards[i].assetContract, address(rewardAssets[i]));
//             assertEq(
//                 _availableRewards[i].rewardAmount,
//                 (((((timeOfLastUpdateLatest - timeOfLastUpdate) * 3)) * rewardTokens[i].rewardAmount) / 3600) +
//                     (((((block.timestamp - timeOfLastUpdateLatest) * 1)) * rewardTokens[i].rewardAmount) / 3600)
//             );
//         }
//     }
// }
