pragma solidity >=0.8.0;

interface IPackEvent {
  event PackCreated(address indexed creator, uint256 indexed tokenId, string tokenUri, uint256 maxSupply);
  event PackRewardsAdded(address indexed creator, uint256 indexed tokenId, uint256[] rewardTokenIds);
  event PackRewardsLocked(address indexed creator, uint256 indexed tokenId);
  event PackOpened(address indexed owner, uint256 indexed tokenId, uint256[] rewardTokenIds);
}
