// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPackEvent {

  event RNGSet(address RNG);

  event PackCreated(address indexed creator, uint indexed tokenId, string tokenUri, uint maxSupply);
  event RewardsAdded(address indexed creator, uint indexed packId, uint[] rewardTokenIds, string[] rewardTokenUris, uint[] rewardTokenMaxSupplies);
  event PackOpened(address indexed owner, uint indexed tokenId, uint randomnessRequestId);
  event RewardDistributed(address indexed receiver, uint indexed packID, uint indexed rewardTokenId);

  event TransferSinglePack(address indexed from, address indexed to, uint indexed tokenId, uint amount);
  event TransferSingleReward(address indexed from, address indexed to, uint indexed tokenId, uint amount);
  event TransferBatchPacks(address indexed from, address indexed to, uint[] ids, uint[] values);
  event TransferBatchRewards(address indexed from, address indexed to, uint[] ids, uint[] values); 
}
