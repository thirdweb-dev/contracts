// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPackEvent {
  event PackCreated(address indexed creator, uint256 indexed tokenId, string tokenUri, uint256 maxSupply);
  event PackRewardsAdded(address indexed creator, uint256 indexed tokenId, uint256[] rewardTokenIds, string[] rewardTokenUris);
  event PackRewardsLocked(address indexed creator, uint256 indexed tokenId);
  event PackOpened(address indexed owner, uint256 indexed tokenId);
  event RewardDistributed(address indexed owner, uint256 indexed packID, uint256 indexed rewardTokenId);

  event TransferSinglePack(address indexed from, address indexed to, uint indexed tokenId, uint amount);
  event TransferSingleReward(address indexed from, address indexed to, uint indexed tokenId, uint amount);
  event TransferBatchPacks(address indexed from, address indexed to, uint256[] ids, uint256[] values);
  event TransferBatchRewards(address indexed from, address indexed to, uint256[] ids, uint256[] values); 
}
